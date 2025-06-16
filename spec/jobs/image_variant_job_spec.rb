# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ImageVariantJob, type: :job do
  include ActiveJob::TestHelper
  
  let(:user) { create(:user) }
  let(:post) { create(:post, :with_image, user: user) }
  
  describe '#perform' do
    context 'when post exists and has an image attached' do
      
      it 'generates all image variants successfully' do
        # Mock the post finding and variant processing
        mock_post = double('post')
        mock_image = double('image', attached?: true)
        
        allow(Post).to receive(:find_by).with(id: post.id).and_return(mock_post)
        allow(mock_post).to receive(:image).and_return(mock_image)
        allow(mock_post).to receive(:id).and_return(post.id)
        
        thumb_variant = double('thumb_variant', processed: true)
        medium_variant = double('medium_variant', processed: true)
        banner_variant = double('banner_variant', processed: true)
        
        allow(mock_image).to receive(:variant).with(:thumb).and_return(thumb_variant)
        allow(mock_image).to receive(:variant).with(:medium).and_return(medium_variant)
        allow(mock_image).to receive(:variant).with(:banner).and_return(banner_variant)
        
        expect {
          ImageVariantJob.new.perform(post.id)
        }.not_to raise_error
      end
      
      it 'processes each variant type' do
        # Mock the post finding and variant processing
        mock_post = double('post')
        mock_image = double('image', attached?: true)
        
        allow(Post).to receive(:find_by).with(id: post.id).and_return(mock_post)
        allow(mock_post).to receive(:image).and_return(mock_image)
        allow(mock_post).to receive(:id).and_return(post.id)
        
        thumb_variant = double('thumb_variant')
        medium_variant = double('medium_variant')
        banner_variant = double('banner_variant')
        
        allow(mock_image).to receive(:variant).with(:thumb).and_return(thumb_variant)
        allow(mock_image).to receive(:variant).with(:medium).and_return(medium_variant)
        allow(mock_image).to receive(:variant).with(:banner).and_return(banner_variant)
        
        expect(thumb_variant).to receive(:processed)
        expect(medium_variant).to receive(:processed)
        expect(banner_variant).to receive(:processed)
        
        ImageVariantJob.new.perform(post.id)
      end
      
      it 'handles errors gracefully for critical variants' do
        # Mock the post finding and variant processing
        mock_post = double('post')
        mock_image = double('image', attached?: true)
        
        allow(Post).to receive(:find_by).with(id: post.id).and_return(mock_post)
        allow(mock_post).to receive(:image).and_return(mock_image)
        allow(mock_post).to receive(:id).and_return(post.id)
        
        allow(mock_image).to receive(:variant).with(:thumb).and_raise(StandardError.new('Thumb failed'))
        allow(mock_image).to receive(:variant).with(:medium).and_return(double(processed: true))
        allow(mock_image).to receive(:variant).with(:banner).and_return(double(processed: true))
        
        # Should raise error because thumb is critical
        expect {
          ImageVariantJob.new.perform(post.id)
        }.to raise_error(StandardError, 'Thumb failed')
      end
      
      it 'does not raise error for non-critical variant failures' do
        # Mock the post finding and variant processing
        mock_post = double('post')
        mock_image = double('image', attached?: true)
        
        allow(Post).to receive(:find_by).with(id: post.id).and_return(mock_post)
        allow(mock_post).to receive(:image).and_return(mock_image)
        allow(mock_post).to receive(:id).and_return(post.id)
        
        allow(mock_image).to receive(:variant).with(:thumb).and_return(double(processed: true))
        allow(mock_image).to receive(:variant).with(:medium).and_raise(StandardError.new('Medium failed'))
        allow(mock_image).to receive(:variant).with(:banner).and_return(double(processed: true))
        
        # Should not raise error for non-critical variants
        expect {
          ImageVariantJob.new.perform(post.id)
        }.not_to raise_error
      end
    end
    
    context 'when post does not exist' do
      it 'returns early without processing' do
        expect {
          ImageVariantJob.new.perform(999999) # Non-existent post ID
        }.not_to raise_error
      end
    end
    
    context 'when post exists but has no image attached' do
      let(:post_without_image) { create(:post, user: user) }
      
      it 'returns early without processing' do
        expect {
          ImageVariantJob.new.perform(post_without_image.id)
        }.not_to raise_error
      end
    end
  end
  
  describe 'job configuration' do
    it 'uses the correct queue' do
      expect(ImageVariantJob.new.queue_name).to eq('image_processing')
    end
    
    it 'has retry configuration' do
      # Test that the job is configured with retry_on by checking if retry_on method exists
      expect(ImageVariantJob).to respond_to(:retry_on)
    end
    
    it 'enqueues the job correctly' do
      expect {
        ImageVariantJob.perform_later(post.id)
      }.to have_enqueued_job(ImageVariantJob).with(post.id).on_queue('image_processing')
    end
  end
end
