# frozen_string_literal: true

class ImageVariantJob < ApplicationJob
  queue_as :image_processing
  
  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  def perform(post_id)
    post = Post.find_by(id: post_id)
    return unless post&.image&.attached?

    Rails.logger.info "Generating image variants for post #{post_id}"
    
    # Generate all variants
    variants = [:thumb, :medium, :banner]
    variants.each do |variant_name|
      begin
        post.image.variant(variant_name).processed
        Rails.logger.info "Generated #{variant_name} variant for post #{post_id}"
      rescue StandardError => e
        Rails.logger.error "Failed to generate #{variant_name} variant for post #{post_id}: #{e.message}"
        raise e if variant_name == :thumb # Retry if thumbnail fails
      end
    end
  end
end
