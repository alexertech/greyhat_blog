# frozen_string_literal: true

class Post < ApplicationRecord
  after_create :update_slug
  before_update :assign_slug
  has_one_attached :image do |attachable|
    attachable.variant :thumb, resize_to_fill: [300, 170], format: :webp
    attachable.variant :medium, resize_to_fill: [600, 400], format: :webp
    attachable.variant :banner, resize_to_fill: [1200, 630], format: :webp
  end
  has_rich_text :body
  has_many :visits, as: :visitable, dependent: :destroy

  def to_param
    slug
  end

  def recent_visits(days = 7)
    visits.where('viewed_at >= ?', days.days.ago).count
  end

  def self.total_unique_visits
    sum(&:unique_visits)
  end

  def self.most_visited(limit = 5)
    joins("LEFT JOIN (SELECT visitable_id, COUNT(*) as visit_count FROM visits 
           WHERE visitable_type = 'Post' GROUP BY visitable_id) AS visit_counts 
           ON posts.id = visit_counts.visitable_id")
      .order('visit_counts.visit_count DESC NULLS LAST')
      .limit(limit)
  end
  
  def self.visits_by_day(days = 7)
    post_ids = pluck(:id)
    return {} if post_ids.empty?
    
    Visit.where(visitable_type: 'Post', visitable_id: post_ids)
         .where('viewed_at >= ?', days.days.ago)
         .group("DATE(viewed_at)")
         .order("DATE(viewed_at)")
         .count
  end

  private

  def assign_slug
    self.slug = title.parameterize.to_s
  end

  def update_slug
    update slug: assign_slug
  end
end
