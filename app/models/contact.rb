# frozen_string_literal: true

class EmailValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value =~ /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i

    record.errors[attribute] << (options[:message] || 'is not an email')
  end
end

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
