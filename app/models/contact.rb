# frozen_string_literal: true

class Contact < ApplicationRecord
  include SpamDetection

  validates :name, presence: true
  validates :email, presence: true, email: true
  validates :message, presence: true

  # Additional validation for email domain
  validate :valid_email_domain

  private

  def valid_email_domain
    return if email.blank?

    # List of suspicious email domains
    suspicious_domains = [
      'mail.com', 'googlemail.com', 'aol.com', 'yandex.ru',
      'mail.ru', 'temp-mail.org', 'tempmail.com', 'guerrillamail.com', 'mailinator.com'
    ]

    # Extract domain
    domain = email.split('@').last&.downcase

    # Check for suspicious domains combined with other spam signals
    return unless domain.present?

    # Check for specific suspicious patterns
    if suspicious_domains.include?(domain) &&
       (message.present? && message.length < 20 ||
        name.present? && !name.match?(/^[A-Za-zÀ-ÖØ-öø-ÿáéíóúüñçÁÉÍÓÚÜÑÇ\s\-'\.]+$/))
      errors.add(:email, 'Por favor utilice un correo electrónico válido')
    end

    # Check for disposable email patterns
    if domain.match?(/temp|fake|disposable|trash|10minutemail|mailinator|guerrilla|throwaway|yopmail|getnada/)
      errors.add(:email, 'Por favor no utilice correos temporales')
    end
  end
end
