# frozen_string_literal: true

class Post < ApplicationRecord
  include Visitable

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
  has_many :comments, dependent: :destroy
  has_many :post_tags, dependent: :destroy
  has_many :tags, through: :post_tags

  scope :published, -> { where(draft: false) }
  scope :drafts, -> { where(draft: true) }

  attr_accessor :tag_names

  def to_param
    slug
  end

  def total_visits
    # Use the counter cache for better performance
    visits_count || 0
  end

  def human_visits
    visits.humans.count
  end

  def unique_visits
    # Use the unique_visits counter cache field if it exists
    read_attribute(:unique_visits) || visits.distinct.count(:ip_address)
  end

  def self.total_unique_visits
    # Use SQL SUM instead of loading all posts into memory
    Post.sum(:unique_visits)
  end

  def engagement_score
    analytics_service.engagement_score
  end

  def newsletter_conversions
    analytics_service.newsletter_conversions
  end

  def liked_by?(ip_address)
    visits.where(ip_address: ip_address, action_type: 'like').exists?
  end

  def like_by!(ip_address)
    return if liked_by?(ip_address)
    
    visits.create!(
      ip_address: ip_address,
      action_type: 'like',
      viewed_at: Time.current
    )
    increment!(:likes_count)
  end

  def unlike_by!(ip_address)
    like_visit = visits.where(ip_address: ip_address, action_type: 'like').first
    return unless like_visit
    
    like_visit.destroy!
    decrement!(:likes_count)
  end

  def performance_trend(days = 3)
    analytics_service.performance_trend(days)
  end

  def self.total_visit_count
    joins(:visits).count
  end

  def self.most_visited(limit = 5)
    # Use counter cache for much better performance
    published
      .includes(:comments, :tags)
      .order(visits_count: :desc)
      .limit(limit)
  end

  def related_posts(limit = 3)
    analytics_service.related_posts(limit)
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

    # Generate variants in background to avoid blocking the request
    ImageVariantJob.perform_later(id)
    Rails.logger.info "Queued image variant generation for post #{id}"
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

  def analytics_service
    @analytics_service ||= PostAnalyticsService.new(self)
  end
end
