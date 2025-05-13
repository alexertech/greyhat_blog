#!/usr/bin/env ruby
# This script migrates old post body content to Action Text
# Run it from the Rails console with: load 'migrate_posts_to_action_text.rb'

# Start a transaction to ensure data consistency
ActiveRecord::Base.transaction do
  # Access the database directly to get all posts with content in the body column
  posts_with_content = ActiveRecord::Base.connection.execute(
    "SELECT id, title, body FROM posts WHERE body IS NOT NULL AND body != ''"
  )
  
  puts "Found #{posts_with_content.count} posts with content in the body column"
  
  # Iterate through each post record
  posts_with_content.each do |post_data|
    post_id = post_data['id']
    post_title = post_data['title']
    old_body_content = post_data['body']
    
    # Skip if this post already has an ActionText record
    if ActionText::RichText.exists?(record_type: 'Post', record_id: post_id, name: 'body')
      puts "Skipping Post ##{post_id}: Already has ActionText content"
      next
    end
    
    # Create a new ActionText rich text record
    action_text = ActionText::RichText.new(
      record_type: 'Post',
      record_id: post_id,
      name: 'body',
      body: old_body_content
    )
    
    if action_text.save
      puts "Migrated Post ##{post_id}: '#{post_title}'"
    else
      puts "Error migrating Post ##{post_id}: #{action_text.errors.full_messages.join(', ')}"
    end
  end
  
  puts "Migration completed. #{posts_with_content.count} posts processed."
end