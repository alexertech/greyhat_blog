namespace :image_variants do
  desc "Pregenerate image variants for all existing posts"
  task pregenerate: :environment do
    posts_with_images = Post.joins(:image_attachment)
    total_posts = posts_with_images.count
    
    puts "Found #{total_posts} posts with images"
    return if total_posts.zero?
    
    success_count = 0
    error_count = 0
    
    posts_with_images.find_each.with_index do |post, index|
      print "\rProcessing post #{index + 1}/#{total_posts}: #{post.title.truncate(50)}"
      
      begin
        # Generate all variants
        post.image.variant(:thumb).processed
        post.image.variant(:medium).processed
        post.image.variant(:banner).processed
        print " ✓"
        success_count += 1
      rescue => e
        print " ✗ (#{e.message})"
        error_count += 1
      end
    end
    
    puts "\n\nVariant generation completed!"
    puts "✓ Success: #{success_count} posts"
    puts "✗ Errors: #{error_count} posts" if error_count > 0
  end
  
  desc "Verify which posts have variants generated"
  task verify: :environment do
    posts_with_images = Post.joins(:image_attachment)
    total_posts = posts_with_images.count
    
    puts "Checking #{total_posts} posts with images for existing variants..."
    
    posts_with_variants = 0
    posts_without_variants = []
    
    posts_with_images.find_each do |post|
      has_variants = begin
        # Try to access each variant - if it exists, this won't raise an error
        post.image.variant(:thumb).key
        post.image.variant(:medium).key
        post.image.variant(:banner).key
        true
      rescue
        false
      end
      
      if has_variants
        posts_with_variants += 1
      else
        posts_without_variants << post.title
      end
    end
    
    puts "\n✓ Posts with all variants: #{posts_with_variants}/#{total_posts}"
    
    if posts_without_variants.any?
      puts "\n⚠ Posts missing variants:"
      posts_without_variants.each { |title| puts "  - #{title}" }
      puts "\nRun 'rails image_variants:pregenerate' to generate missing variants."
    else
      puts "\n All posts have their variants generated!"
    end
  end
  
  desc "Clean up unused image variants"
  task cleanup: :environment do
    puts "Cleaning up unused variants..."
    
    # This would require custom logic based on your storage setup
    # For now, just notify about manual cleanup
    puts "Manual cleanup may be needed for unused variants in storage/"
    puts "Consider running this periodically to free up disk space."
  end
end 