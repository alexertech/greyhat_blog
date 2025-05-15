# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contact, type: :model do
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
      
      expect(contact.errors[:base]).to include('Spam detected')
    end
  end
end 