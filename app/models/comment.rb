# frozen_string_literal: true

class Comment < ApplicationRecord
  include SpamDetection

  belongs_to :post, counter_cache: true

  # Scopes
  scope :approved, -> { where(approved: true) }
  scope :pending, -> { where(approved: false) }

  # Callbacks for approved_comments_count
  after_create :increment_approved_count, if: :approved?
  after_update :update_approved_count, if: :saved_change_to_approved?
  after_destroy :decrement_approved_count, if: :approved?

  # Validations
  validates :username, presence: true
  validates :email, presence: true, email: true
  validates :body, presence: true, length: { maximum: 140 }

  # Additional validations for comment quality
  validate :message_quality

  private

  # Approved comments counter cache management
  def increment_approved_count
    post.increment!(:approved_comments_count)
  end

  def decrement_approved_count
    post.decrement!(:approved_comments_count)
  end

  def update_approved_count
    if approved?
      post.increment!(:approved_comments_count)
    else
      post.decrement!(:approved_comments_count)
    end
  end

  # Methods for specific comment validations
  def message_quality
    return if body.blank?

    # Check if message is too short
    errors.add(:body, I18n.t('errors.messages.comment_too_short', default: 'Comment is too short')) if body.length < 3

    # Check for suspicious content patterns
    words = body.downcase.scan(/\w+/)
    return unless words.length >= 5 && words.uniq.length < words.length / 3

    errors.add(:body,
               I18n.t('errors.messages.repetitive_content', default: 'Comment appears to contain repetitive text'))
  end
end
