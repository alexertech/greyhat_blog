# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    it 'is valid with valid attributes' do
      user = User.new(email: 'test@example.com', password: 'password123456')
      expect(user).to be_valid
    end

    it 'is not valid without an email' do
      user = User.new(password: 'password123456')
      expect(user).not_to be_valid
    end

    it 'is not valid without a password' do
      user = User.new(email: 'test@example.com')
      expect(user).not_to be_valid
    end

    it 'is not valid with a duplicate email' do
      User.create(email: 'test@example.com', password: 'password123456')
      user = User.new(email: 'test@example.com', password: 'password654321')
      expect(user).not_to be_valid
    end
  end

  describe 'devise modules' do
    it 'includes database_authenticatable module' do
      expect(User.devise_modules).to include(:database_authenticatable)
    end

    it 'includes recoverable module' do
      expect(User.devise_modules).to include(:recoverable)
    end

    it 'includes rememberable module' do
      expect(User.devise_modules).to include(:rememberable)
    end

    it 'includes validatable module' do
      expect(User.devise_modules).to include(:validatable)
    end
    
    it 'includes lockable module' do
      expect(User.devise_modules).to include(:lockable)
    end
    
    it 'includes timeoutable module' do
      expect(User.devise_modules).to include(:timeoutable)
    end
    
    it 'includes trackable module' do
      expect(User.devise_modules).to include(:trackable)
    end
  end
end 