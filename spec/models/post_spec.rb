# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Post, type: :model do
  context 'post' do
    xit 'creates a post with attachment' do
      subject = Post.new

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
      subject = Post.create(title: 'Test Post', body: 'Test Body')
      expect(subject.draft).to be(false)
    end
    
    describe 'scopes' do
      before do
        Post.create(title: 'Published Post 1', body: 'Content', draft: false)
        Post.create(title: 'Published Post 2', body: 'Content', draft: false)
        Post.create(title: 'Draft Post 1', body: 'Content', draft: true)
        Post.create(title: 'Draft Post 2', body: 'Content', draft: true)
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
