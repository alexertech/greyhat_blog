# Active Storage Configuration
Rails.application.configure do
  # Set the variant processor to use vips with image_processing gem
  config.active_storage.variant_processor = :vips
  
  # Enable WebP support
  config.active_storage.web_image_content_types = %w[image/png image/jpeg image/gif image/webp]
  
  # Precompile assets for better performance
  config.active_storage.precompile_assets = true
end 