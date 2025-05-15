# frozen_string_literal: true

class Comment < ApplicationRecord
  belongs_to :post
  
  # Hidden field for honeypot spam detection
  attr_accessor :website
  
  # Validations
  validates :username, presence: true
  validates :email, presence: true, email: true
  validates :body, presence: true, length: { maximum: 140 }
  
  # Custom validations
  validate :no_links
  validate :honeypot_empty
  
  private
  
  def no_links
    if body&.match?(/https?:\/\/|www\./)
      errors.add(:body, "cannot contain links")
    end
  end
  
  def honeypot_empty
    errors.add(:base, "Spam detected") unless website.blank?
  end
end 