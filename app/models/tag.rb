# frozen_string_literal: true

class Tag < ApplicationRecord
  has_many :post_tags, dependent: :destroy
  has_many :posts, through: :post_tags
  
  validates :name, presence: true, uniqueness: { case_sensitive: false }
  
  before_save :normalize_name
  
  scope :popular, -> { joins(:posts).group('tags.id').order('COUNT(posts.id) DESC') }
  
  def to_param
    name.downcase
  end
  
  private
  
  def normalize_name
    self.name = name.strip.downcase
  end
end
