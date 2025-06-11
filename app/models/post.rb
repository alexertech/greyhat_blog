# frozen_string_literal: true

class Post < ApplicationRecord
  validates :title, presence: true, length: { minimum: 1 }
  validates :body, presence: true
  validates :user_id, presence: true

  after_create :update_slug
  before_update :assign_slug
  after_save :assign_tags
  after_save :generate_variants_if_image_changed
  has_one_attached :image do |attachable|
    attachable.variant :thumb, resize_to_fill: [480, 148], format: :webp
    attachable.variant :medium, resize_to_fill: [768, 237], format: :webp
    attachable.variant :banner, resize_to_fill: [1536, 474], format: :webp
  end
  has_rich_text :body
  belongs_to :user
  has_many :visits, as: :visitable, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :post_tags, dependent: :destroy
  has_many :tags, through: :post_tags

  scope :published, -> { where(draft: false) }
  scope :drafts, -> { where(draft: true) }

  attr_accessor :tag_names

  def to_param
    slug
  end

  def recent_visits(days = 7)
    visits.where('viewed_at >= ?', days.days.ago).count
  end

  def total_visits
    # Use the counter cache if available, otherwise query
    self[:unique_visits] || visits.count
  end

  def human_visits
    visits.humans.count
  end

  def unique_visits
    # Use database COUNT DISTINCT instead of loading data into memory
    visits.distinct.count(:ip_address)
  end

  def self.total_unique_visits
    # Use SQL SUM instead of loading all posts into memory
    Post.sum(:unique_visits)
  end

  def engagement_score
    # Use cached values when available to avoid repeated database queries
    visit_count = self.unique_visits || 0
    return 0 if visit_count.zero?
    
    # Weighted score: views (40%) + comments (40%) + recent activity (20%)
    view_score = [visit_count / 100.0, 10].min * 4
    comment_score = [comments.approved.count * 2, 10].min * 4
    recent_score = [recent_visits(7) / 10.0, 10].min * 2
    
    (view_score + comment_score + recent_score).round(1)
  end

  def newsletter_conversions
    # Optimized query using proper indexing - will be fast once indexes are applied
    Visit.where(visitable_type: 'Page', visitable_id: 5, action_type: 'newsletter_click')
         .joins("JOIN visits referer_visits ON referer_visits.ip_address = visits.ip_address")
         .where("referer_visits.visitable_type = 'Post' AND referer_visits.visitable_id = ?", id)
         .where("visits.viewed_at - referer_visits.viewed_at BETWEEN INTERVAL '0 minutes' AND INTERVAL '1 hour'")
         .where("referer_visits.viewed_at < visits.viewed_at")
         .count
  end

  def performance_trend(days = 3)
    # Compare last 3 days vs previous 3 days for more relevant trends
    current_period = visits.where('viewed_at >= ?', days.days.ago).count
    previous_period = visits.where('viewed_at >= ? AND viewed_at < ?', 
                                   (days * 2).days.ago, days.days.ago).count
    
    # If no previous data, show trend based on post age
    if previous_period.zero?
      return current_period > 0 ? 100 : 0
    end
    
    # Cap extreme values for better UX
    trend = ((current_period - previous_period) / previous_period.to_f * 100).round(1)
    [[-95, trend].max, 500].min  # Cap between -95% and +500%
  end

  def self.total_visit_count
    joins(:visits).count
  end

  def self.most_visited(limit = 5)
    joins("LEFT JOIN (SELECT visitable_id, COUNT(*) as visit_count FROM visits
           WHERE visitable_type = 'Post' GROUP BY visitable_id) AS visit_counts
           ON posts.id = visit_counts.visitable_id")
      .includes(:comments, :tags)
      .order('visit_counts.visit_count DESC NULLS LAST')
      .limit(limit)
  end

  def related_posts(limit = 3)
    return Post.published.where.not(id: id).limit(limit) if tags.empty?

    # Use a subquery approach to avoid GROUP BY issues with includes
    related_post_ids = Post.published
                           .joins(:tags)
                           .where(tags: { id: tag_ids })
                           .where.not(id: id)
                           .group('posts.id')
                           .order('COUNT(tags.id) DESC, posts.created_at DESC')
                           .limit(limit)
                           .pluck(:id)

    return Post.published.where.not(id: id).limit(limit) if related_post_ids.empty?

    Post.where(id: related_post_ids)
        .order(Arel.sql("array_position(ARRAY[#{related_post_ids.join(',')}], posts.id)"))
  end

  def self.visits_by_day(days = 7)
    post_ids = pluck(:id)
    return {} if post_ids.empty?

    Visit.where(visitable_type: 'Post', visitable_id: post_ids)
         .where('viewed_at >= ?', days.days.ago)
         .group('DATE(viewed_at)')
         .order('DATE(viewed_at)')
         .count
  end

  private

  def assign_slug
    self.slug = title.parameterize.to_s
  end

  def update_slug
    update_column(:slug, title.parameterize.to_s)
  end

  def generate_variants_if_image_changed
    return unless image.attached? && image.attachment&.created_at
    
    # Only generate variants if image was actually changed/attached
    return unless image.attachment.created_at >= 1.minute.ago || 
                  (saved_changes.key?('updated_at') && image.attachment.created_at >= updated_at - 1.minute)

    # Generate variants only when image is new or changed
    begin
      image.variant(:thumb).processed
      image.variant(:medium).processed
      image.variant(:banner).processed

      Rails.logger.info "Generated image variants for post #{id}"
    rescue StandardError => e
      Rails.logger.error "Failed to generate variants for post #{id}: #{e.message}"
    end
  end

  def assign_tags
    return unless tag_names.present?

    begin
      # Clear existing tags
      tags.clear

      # Parse and create/assign new tags
      tag_list = tag_names.split(',').map(&:strip).reject(&:blank?)
      tag_list.each do |tag_name|
        tag = Tag.find_or_create_by(name: tag_name.downcase)
        tags << tag unless tags.include?(tag)
      end
    rescue StandardError => e
      Rails.logger.error "Failed to assign tags for post #{id}: #{e.message}"
    end
  end
end
