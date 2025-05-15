# frozen_string_literal: true

class Contact < ApplicationRecord
  attr_accessor :website
  
  validates :name, presence: true
  validates :email, presence: true, email: true
  validates :message, presence: true
  
  # Honeypot validation - website field should be empty
  validate :honeypot_empty
  
  private
  
  def honeypot_empty
    errors.add(:base, "Spam detected") unless website.blank?
  end
end
