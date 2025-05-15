# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Comment, type: :model do
  let(:post) { Post.create(title: 'Test Post', body: 'Test body content') }
  
  describe 'validations' do
    it 'is valid with valid attributes' do
      comment = Comment.new(
        post: post,
        username: 'User123',
        email: 'user@example.com',
        body: 'This is a valid comment',
        website: ''
      )
      expect(comment).to be_valid
    end

    it 'is not valid without a username' do
      comment = Comment.new(
        post: post,
        email: 'user@example.com',
        body: 'Test comment'
      )
      expect(comment).not_to be_valid
      expect(comment.errors[:username]).to include("can't be blank")
    end

    it 'is not valid without an email' do
      comment = Comment.new(
        post: post,
        username: 'User123',
        body: 'Test comment'
      )
      expect(comment).not_to be_valid
      expect(comment.errors[:email]).to include("can't be blank")
    end

    it 'is not valid without a body' do
      comment = Comment.new(
        post: post,
        username: 'User123',
        email: 'user@example.com'
      )
      expect(comment).not_to be_valid
      expect(comment.errors[:body]).to include("can't be blank")
    end
    
    it 'is not valid with a body longer than 140 characters' do
      comment = Comment.new(
        post: post,
        username: 'User123',
        email: 'user@example.com',
        body: 'a' * 141
      )
      expect(comment).not_to be_valid
      expect(comment.errors[:body]).to include("is too long (maximum is 140 characters)")
    end
    
    it 'is not valid if body contains links' do
      comment = Comment.new(
        post: post,
        username: 'User123',
        email: 'user@example.com',
        body: 'Check out https://example.com'
      )
      expect(comment).not_to be_valid
      expect(comment.errors[:body]).to include("cannot contain links")
      
      comment.body = 'Visit www.example.com'
      expect(comment).not_to be_valid
      expect(comment.errors[:body]).to include("cannot contain links")
    end
    
    it 'detects spam if website field is filled' do
      comment = Comment.new(
        post: post,
        username: 'User123',
        email: 'user@example.com',
        body: 'Test comment',
        website: 'https://spammer.com'
      )
      
      expect(comment).not_to be_valid
      expect(comment.errors[:base]).to include('Spam detected')
    end
  end
end 