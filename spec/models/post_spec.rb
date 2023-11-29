# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Post, type: :model do
  context 'post' do
    it 'create 1a post with atachment' do
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
  end
end
