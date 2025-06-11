# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Post, type: :model do
  describe 'validations' do
    it 'is valid with valid attributes' do
      user = create(:user)
      post = Post.new(title: 'Test Post', body: 'Test Body', user: user)
      expect(post).to be_valid
    end

    it 'is not valid without a title' do
      user = create(:user)
      post = Post.new(body: 'Test Body', user: user)
      expect(post).not_to be_valid
    end

    it 'is not valid without a body' do
      user = create(:user)
      post = Post.new(title: 'Test Post', user: user)
      expect(post).not_to be_valid
    end

    it 'is not valid without a user' do
      post = Post.new(title: 'Test Post', body: 'Test Body')
      expect(post).not_to be_valid
    end
  end

  describe 'associations' do
    it 'belongs to user' do
      association = Post.reflect_on_association(:user)
      expect(association.macro).to eq :belongs_to
    end

    it 'has many visits' do
      association = Post.reflect_on_association(:visits)
      expect(association.macro).to eq :has_many
    end

    it 'has many comments' do
      association = Post.reflect_on_association(:comments)
      expect(association.macro).to eq :has_many
    end

    it 'has many tags through post_tags' do
      association = Post.reflect_on_association(:tags)
      expect(association.macro).to eq :has_many
      expect(association.options[:through]).to eq :post_tags
    end
  end
  
  context 'post' do
    xit 'creates a post with attachment' do
      user = create(:user)
      subject = Post.new
      subject.user = user
      subject.title = 'title'
      subject.body =  'body'
      subject.image.attach(
        io: File.open(Rails.root.join('spec', 'fixtures', 'files', 'image.jpg')),
        filename: 'image.jpg',
        content_type: 'image/jpeg'
      )
      subject.save!

      expect(subject).to be_valid
      expect(subject.image).to be_attached
      expect(subject.image).to be_an_instance_of(ActiveStorage::Attached::One)
      expect(subject.image.blob.filename).not_to be_nil
    end
    
    it 'defaults to not being a draft' do
      user = create(:user)
      subject = Post.create(title: 'Test Post', body: 'Test Body', user: user)
      expect(subject.draft).to be(false)
    end
    
    describe 'scopes' do
      before do
        user = create(:user)
        Post.create(title: 'Published Post 1', body: 'Content', draft: false, user: user)
        Post.create(title: 'Published Post 2', body: 'Content', draft: false, user: user)
        Post.create(title: 'Draft Post 1', body: 'Content', draft: true, user: user)
        Post.create(title: 'Draft Post 2', body: 'Content', draft: true, user: user)
      end
      
      it 'returns only published posts with published scope' do
        expect(Post.published.count).to eq(2)
        expect(Post.published.map(&:title)).to include('Published Post 1', 'Published Post 2')
        expect(Post.published.map(&:title)).not_to include('Draft Post 1', 'Draft Post 2')
      end
      
      it 'returns only draft posts with drafts scope' do
        expect(Post.drafts.count).to eq(2)
        expect(Post.drafts.map(&:title)).to include('Draft Post 1', 'Draft Post 2')
        expect(Post.drafts.map(&:title)).not_to include('Published Post 1', 'Published Post 2')
      end
    end
  end
end
