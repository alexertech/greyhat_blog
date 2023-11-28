# frozen_string_literal: true

class Post < ApplicationRecord
  after_create :update_slug
  before_update :assign_slug
  has_one_attached :image

  def to_param
    slug
  end

  private

  def assign_slug
    self.slug = title.parameterize.to_s
  end

  def update_slug
    update slug: assign_slug
  end

  def self.total_unique_visits
    sum(&:unique_visits)
  end
end
