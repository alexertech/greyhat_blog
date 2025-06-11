# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    it 'is valid with valid attributes' do
      user = User.new(email: 'test@example.com', password: 'password123456', public_name: 'Test User')
      expect(user).to be_valid
    end

    it 'is not valid without an email' do
      user = User.new(password: 'password123456', public_name: 'Test User')
      expect(user).not_to be_valid
    end

    it 'is not valid without a password' do
      user = User.new(email: 'test@example.com', public_name: 'Test User')
      expect(user).not_to be_valid
    end

    it 'is not valid without a public_name' do
      user = User.new(email: 'test@example.com', password: 'password123456')
      expect(user).not_to be_valid
    end

    it 'is not valid with a duplicate email' do
      User.create(email: 'test@example.com', password: 'password123456', public_name: 'Test User')
      user = User.new(email: 'test@example.com', password: 'password654321', public_name: 'Another User')
      expect(user).not_to be_valid
    end
  end

  describe 'associations' do
    it 'has many posts' do
      association = User.reflect_on_association(:posts)
      expect(association.macro).to eq :has_many
    end

    it 'destroys associated posts when user is destroyed' do
      association = User.reflect_on_association(:posts)
      expect(association.options[:dependent]).to eq :destroy
    end

    it 'has one attached avatar' do
      user = User.new
      expect(user.respond_to?(:avatar)).to be true
    end
  end

  describe '#display_name' do
    it 'returns public_name when present' do
      user = User.new(public_name: 'John Doe', email: 'john@example.com')
      expect(user.display_name).to eq 'John Doe'
    end

    it 'returns capitalized email username when public_name is blank' do
      user = User.new(public_name: '', email: 'john.doe@example.com')
      expect(user.display_name).to eq 'John'
    end

    it 'returns capitalized email username when public_name is nil' do
      user = User.new(public_name: nil, email: 'jane@example.com')
      expect(user.display_name).to eq 'Jane'
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