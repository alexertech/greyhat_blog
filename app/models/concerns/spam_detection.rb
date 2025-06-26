# frozen_string_literal: true

module SpamDetection
  extend ActiveSupport::Concern

  included do
    # Hidden field for honeypot spam detection
    attr_accessor :website, :form_displayed_at
    
    # Common spam validations
    validate :honeypot_empty
    validate :no_links_in_content
    validate :no_spam_keywords
    validate :valid_name_format
    # TODO: Revisit this validation
    # validate :check_submission_time
  end

  private

  def honeypot_empty
    errors.add(:base, I18n.t('errors.messages.spam_detected', default: "Spam detectado")) unless website.blank?
  end

  def no_links_in_content
    # Determine fields to check based on model
    text_fields = []
    text_fields << name if respond_to?(:name)
    text_fields << username if respond_to?(:username)
    text_fields << message if respond_to?(:message)
    text_fields << body if respond_to?(:body)
    
    # Common link patterns
    link_patterns = [
      /https?:\/\//, /www\./, /\.com/, /\.net/, /\.org/, /\.info/,
      /\.biz/, /bit\.ly/, /tinyurl/, /\.io/, /goo\.gl/, /\.xyz/,
      /\.onion/, /\.link/, /<a\s+href/i, /href=/, /url=/, /link=/
    ]
    
    if text_fields.any? { |field| field.present? && link_patterns.any? { |pattern| field.match?(pattern) } }
      error_message = I18n.t('errors.messages.no_links', default: "No se permiten enlaces en el contenido")
      errors.add(:base, error_message)
    end
  end

  def no_spam_keywords
    # Common spam keywords and phrases
    spam_keywords = [
      'bitcoin', 'crypto', 'captcha', '1xbet', 'slot', 'bet', 'casino', 'bonus', 'porn',
      'viagra', 'cialis', 'win', 'prize', 'lottery', 'weight loss', 'diet', 'slim', 'drops',
      'loan', 'credit', 'free money', 'free consultation', 'seo', 'backlinks', 'traffic',
      'tinyurl', 'bitly', 'promocion', 'promo code', 'jews', 'astonishing', 'software for',
      'effortlessly', 'stunning', 'discovered', 'miracle', 'transforming', 'fast', 'spin', 
      'captchas', 'solving', 'promotional', 'promoción', 'click here', 'get rich', 'easy money'
    ]
    
    # Content to check
    full_content = ""
    full_content += "#{name} " if respond_to?(:name)
    full_content += "#{username} " if respond_to?(:username)
    full_content += "#{email} " if respond_to?(:email)
    full_content += "#{message} " if respond_to?(:message)
    full_content += "#{body} " if respond_to?(:body)
    full_content = full_content.downcase
    
    # Check for spam keywords
    if spam_keywords.any? { |keyword| full_content.include?(keyword) }
      error_message = I18n.t('errors.messages.contains_spam_words', default: "El mensaje contiene palabras o frases no permitidas")
      errors.add(:base, error_message)
    end
    
    # Check for excessive capitalization in message or body field
    text_content = respond_to?(:message) ? message : (respond_to?(:body) ? body : nil)
    if text_content.present? && text_content.count("A-Z").to_f / text_content.count("A-Za-z").to_f > 0.3
      error_field = respond_to?(:message) ? :message : :body
      error_message = I18n.t('errors.messages.too_many_capitals', default: "El texto contiene demasiadas letras mayúsculas")
      errors.add(error_field, error_message)
    end
  end

  def valid_name_format
    # Determine the name field based on model
    name_field = respond_to?(:name) ? name : (respond_to?(:username) ? username : nil)
    return if name_field.blank?
    
    # Field name for error message
    error_field = respond_to?(:name) ? :name : :username
    
    # Valid name should only contain letters, spaces, hyphens and apostrophes
    # and should have at least 2 characters and no more than 50
    # Includes all Spanish accented characters: áéíóúüñçÁÉÍÓÚÜÑÇ
    unless name_field.match?(/^[A-Za-zÀ-ÖØ-öø-ÿáéíóúüñçÁÉÍÓÚÜÑÇ\s\-'\.]{2,50}$/)
      error_message = I18n.t('errors.messages.invalid_name', default: "Por favor ingrese un nombre válido")
      errors.add(error_field, error_message)
    end
    
    # Check for repetitive patterns that bots often use
    if name_field.match?(/(.)\1{3,}/) || # Same character repeated 4+ times
       name_field.match?(/(.{2,})\1{2,}/) # Same 2+ character pattern repeated 3+ times
      error_message = I18n.t('errors.messages.invalid_name_pattern', default: "Por favor ingrese un nombre válido")
      errors.add(error_field, error_message)
    end
  end

  def check_submission_time
    # Skip this validation if form_displayed_at is not set
    return unless form_displayed_at.present?
    
    # Convert to Time object if it's a string
    display_time = form_displayed_at.is_a?(String) ? Time.parse(form_displayed_at) : form_displayed_at
    
    # Calculate the time difference in seconds
    time_diff = Time.current - display_time
    
    # If form was submitted too quickly (less than 1 second), it's probably a bot
    # Reduced from 3 seconds to 1 second to accommodate fast typers
    if time_diff < 1
      error_message = I18n.t('errors.messages.submission_too_fast', default: "Por favor complete el formulario más despacio")
      errors.add(:base, error_message)
    end
  end
end 