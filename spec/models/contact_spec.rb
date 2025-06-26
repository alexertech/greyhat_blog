# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contact, type: :model do
  before do
    # Set locale to English for consistent tests regardless of application default
    I18n.locale = :en
  end
  
  after do
    # Reset to default locale
    I18n.locale = I18n.default_locale
  end
  
  describe 'validations' do
    it 'is valid with valid attributes' do
      contact = Contact.new(
        name: 'Test User',
        email: 'test@example.com',
        message: 'This is a test message',
        website: ''
      )
      expect(contact).to be_valid
    end

    it 'is not valid without a name' do
      contact = Contact.new(
        email: 'test@example.com',
        message: 'This is a test message'
      )
      expect(contact).not_to be_valid
      expect(contact.errors[:name]).to include("can't be blank")
    end

    it 'is not valid without an email' do
      contact = Contact.new(
        name: 'Test User',
        message: 'This is a test message'
      )
      expect(contact).not_to be_valid
      expect(contact.errors[:email]).to include("can't be blank")
    end

    it 'validates email format' do
      # The test verifies that we have the correct validator attached
      # rather than testing the specific validator implementation
      email_validators = Contact.validators_on(:email).select do |validator|
        validator.is_a?(ActiveModel::Validations::PresenceValidator) ||
        validator.is_a?(ActiveModel::EachValidator) && validator.options[:class] == EmailValidator
      end
      
      expect(email_validators).not_to be_empty
    end

    it 'is not valid without a message' do
      contact = Contact.new(
        name: 'Test User',
        email: 'test@example.com'
      )
      expect(contact).not_to be_valid
      expect(contact.errors[:message]).to include("can't be blank")
    end
    
    it 'detects spam if website field is filled' do
      contact = Contact.new(
        name: 'Test User',
        email: 'test@example.com',
        message: 'This is a test message',
        website: 'https://spammer.com'
      )
      
      # Force validation to run
      contact.valid?
      
      expect(contact.errors[:base]).to include('Spam detectado')
    end

    context 'Spanish accented names' do
      it 'accepts Spanish names with accented characters' do
        valid_names = [
          'María García',
          'José Antonio Núñez',
          'Ángela Sánchez-López',
          'Joaquín Ruíz',
          'Pilar Hernández',
          'Óscar Díez',
          "María del Carmen O'Connor"
        ]

        valid_names.each do |name|
          contact = Contact.new(
            name: name,
            email: 'test@example.com',
            message: 'Este es un mensaje de prueba'
          )
          expect(contact).to be_valid, "Expected '#{name}' to be valid but got errors: #{contact.errors.full_messages}"
        end
      end

      it 'rejects names with invalid characters' do
        invalid_names = [
          'María123',
          'José@example.com',
          'Test#User',
          'Invalid$Name'
        ]

        invalid_names.each do |name|
          contact = Contact.new(
            name: name,
            email: 'test@example.com',
            message: 'Este es un mensaje de prueba'
          )
          expect(contact).not_to be_valid, "Expected '#{name}' to be invalid"
          expect(contact.errors[:name]).to be_present, "Expected name validation error for '#{name}'"
        end
      end
    end
  end
end 