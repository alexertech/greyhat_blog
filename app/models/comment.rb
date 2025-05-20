# frozen_string_literal: true

class Comment < ApplicationRecord
  include SpamDetection
  
  belongs_to :post
  
  # Scopes
  scope :approved, -> { where(approved: true) }
  scope :pending, -> { where(approved: false) }
  
  # Validations
  validates :username, presence: true
  validates :email, presence: true, email: true
  validates :body, presence: true, length: { maximum: 140 }
  
  # Additional validations for comment quality
  validate :message_quality
  
  private
  

  
  # Methods for specific comment validations
  def message_quality
    return if body.blank?
    
    # Check if message is too short
    if body.length < 3
      errors.add(:body, I18n.t('errors.messages.comment_too_short', default: "Comment is too short"))
    end
    
    # Check for suspicious content patterns
    words = body.downcase.scan(/\w+/)
    if words.length >= 5 && words.uniq.length < words.length / 3
      errors.add(:body, I18n.t('errors.messages.repetitive_content', default: "Comment appears to contain repetitive text"))
    end
  end
end 