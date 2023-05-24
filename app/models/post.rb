class Post < ApplicationRecord
  after_create :update_slug
  before_update :assign_slug
  has_one_attached :image

  def to_param
    slug
  end

  private

  def assign_slug
    self.slug = "#{title.parameterize}"
  end

  def update_slug
    update slug: assign_slug
  end

  def total_unique_visits
    self.sum { |record| record.unique_visits }
  end

end
