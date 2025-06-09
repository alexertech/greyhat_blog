# frozen_string_literal: true

class Post < ApplicationRecord
  validates :title, presence: true, length: { minimum: 1 }
  validates :body, presence: true

  after_create :update_slug
  before_update :assign_slug
  after_commit :generate_image_variants, on: %i[create update]
  after_save :assign_tags
  has_one_attached :image do |attachable|
    attachable.variant :thumb, resize_to_fill: [480, 148], format: :webp
    attachable.variant :medium, resize_to_fill: [768, 237], format: :webp
    attachable.variant :banner, resize_to_fill: [1536, 474], format: :webp
  end
  has_rich_text :body
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
    visits.count
  end

  def human_visits
    visits.humans.count
  end

  def unique_visits
    visits.group(:ip_address).count.keys.count
  end

  def self.total_unique_visits
    sum(&:unique_visits)
  end

  def engagement_score
    return 0 if total_visits.zero?
    
    # Weighted score: views (40%) + comments (40%) + recent activity (20%)
    view_score = [total_visits / 100.0, 10].min * 4
    comment_score = [comments.approved.count * 2, 10].min * 4
    recent_score = [recent_visits(7) / 10.0, 10].min * 2
    
    (view_score + comment_score + recent_score).round(1)
  end

  def newsletter_conversions
    # Track visits to newsletter page that came from this post
    Visit.joins("JOIN visits referer_visits ON referer_visits.id < visits.id")
         .where(visitable_type: 'Page', visitable_id: 5) # Newsletter page
         .where("referer_visits.visitable_type = 'Post' AND referer_visits.visitable_id = ?", id)
         .where("visits.viewed_at - referer_visits.viewed_at < INTERVAL '1 hour'")
         .count
  end

  def performance_trend(days = 7)
    current_period = recent_visits(days)
    previous_period = visits.where('viewed_at >= ? AND viewed_at < ?', 
                                   (days * 2).days.ago, days.days.ago).count
    
    return 0 if previous_period.zero?
    
    ((current_period - previous_period) / previous_period.to_f * 100).round(1)
  end

  def self.total_visit_count
    joins(:visits).count
  end

  def self.most_visited(limit = 5)
    joins("LEFT JOIN (SELECT visitable_id, COUNT(*) as visit_count FROM visits
           WHERE visitable_type = 'Post' GROUP BY visitable_id) AS visit_counts
           ON posts.id = visit_counts.visitable_id")
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
    update slug: assign_slug
  end

  def generate_image_variants
    return unless image.attached?

    # Generate variants synchronously
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

    # Clear existing tags
    tags.clear

    # Parse and create/assign new tags
    tag_list = tag_names.split(',').map(&:strip).reject(&:blank?)
    tag_list.each do |tag_name|
      tag = Tag.find_or_create_by(name: tag_name.downcase)
      tags << tag unless tags.include?(tag)
    end
  end
end
