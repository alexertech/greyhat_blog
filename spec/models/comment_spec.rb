# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Comment, type: :model do
  let(:post_obj) { Post.create(title: 'Test Post', body: 'Test body content') }
  
  # Helper method to build a valid comment
  def build_valid_comment(overrides = {})
    Comment.new({
      post: post_obj,
      username: 'María García',
      email: 'user@example.com',
      body: 'This is a valid comment',
      website: ''
    }.merge(overrides))
  end
  
  before do
    I18n.locale = :es
  end
  
  after do
    I18n.locale = I18n.default_locale
  end
  
  describe 'validations' do
    context 'with valid attributes' do
      it 'is valid with standard attributes' do
        comment = build_valid_comment
        expect(comment).to be_valid
      end
      
      it 'is valid with exactly 140 characters in body' do
        comment = build_valid_comment(body: 'a' * 140)
        expect(comment).to be_valid
      end
      
      it 'is valid with empty website field' do
        comment = build_valid_comment(website: '')
        expect(comment).to be_valid
      end
      
      it 'is valid with nil website field' do
        comment = build_valid_comment(website: nil)
        expect(comment).to be_valid
      end
    end
    
    context 'with invalid attributes' do
      it 'is not valid without a username' do
        comment = build_valid_comment(username: nil)
        expect(comment).not_to be_valid
        expect(comment.errors[:username]).to include("no puede estar en blanco")
      end
      
      it 'is not valid with an empty username' do
        comment = build_valid_comment(username: '')
        expect(comment).not_to be_valid
        expect(comment.errors[:username]).to include("no puede estar en blanco")
      end

      it 'is not valid without an email' do
        comment = build_valid_comment(email: nil)
        expect(comment).not_to be_valid
        expect(comment.errors[:email]).to include("no puede estar en blanco")
      end
      
      it 'is not valid with an empty email' do
        comment = build_valid_comment(email: '')
        expect(comment).not_to be_valid
        expect(comment.errors[:email]).to include("no puede estar en blanco")
      end
      
      it 'is not valid without a body' do
        comment = build_valid_comment(body: nil)
        expect(comment).not_to be_valid
        expect(comment.errors[:body]).to include("no puede estar en blanco")
      end
      
      it 'is not valid with an empty body' do
        comment = build_valid_comment(body: '')
        expect(comment).not_to be_valid
        expect(comment.errors[:body]).to include("no puede estar en blanco")
      end
    end
    
    context 'with length constraints' do
      it 'is not valid with a body longer than 140 characters' do
        comment = build_valid_comment(body: 'a' * 141)
        expect(comment).not_to be_valid
        expect(comment.errors[:body]).to include("es demasiado largo (máximo 140 caracteres)")
      end
    end
    
    context 'with anti-spam measures' do
      it 'detects spam if website field is filled' do
        comment = build_valid_comment(website: 'https://spammer.com')
        expect(comment).not_to be_valid
        expect(comment.errors[:base]).to include('Spam detectado')
      end
      
      it 'is not valid if body contains http links' do
        comment = build_valid_comment(body: 'Check out https://example.com')
        expect(comment).not_to be_valid
        expect(comment.errors[:base]).to include("No se permiten enlaces en el contenido")
      end
      
      it 'is not valid if body contains www links' do
        comment = build_valid_comment(body: 'Visit www.example.com')
        expect(comment).not_to be_valid
        expect(comment.errors[:base]).to include("No se permiten enlaces en el contenido")
      end
      
      it 'rejects subtle link attempts' do
        comment = build_valid_comment(body: 'Go to example.com for more info')
        expect(comment).not_to be_valid
        expect(comment.errors[:base]).to include("No se permiten enlaces en el contenido")
      end
    end
  end
  
  describe 'associations' do
    it 'belongs to a post' do
      association = Comment.reflect_on_association(:post)
      expect(association.macro).to eq :belongs_to
    end
    
    it 'is destroyed when the associated post is destroyed' do
      post_with_comment = Post.create!(title: 'Post with comment', body: 'Test content')
      comment = post_with_comment.comments.create!(
        username: 'María García',
        email: 'user@example.com',
        body: 'Test comment'
      )
      
      expect { post_with_comment.destroy }.to change { Comment.count }.by(-1)
      expect(Comment.exists?(comment.id)).to be false
    end
  end
end 