class MigratePostsBodyToActionText < ActiveRecord::Migration[7.2]
  def up
    # Find all existing posts that have body content
    Post.find_each do |post|
      # Skip if the post doesn't have a body or it's already been processed
      next if post.body.blank? || ActionText::RichText.exists?(record_type: 'Post', record_id: post.id, name: 'body')

      # Convert markdown to ActionText content
      markdown_body = post.body
      
      # Create ActionText record for this post
      ActionText::RichText.create!(
        record_type: 'Post',
        record_id: post.id,
        name: 'body',
        body: markdown_body
      )
    end
  end

  def down
    # This migration is not reversible as it would require knowing which
    # content was originally markdown and which was added later
    raise ActiveRecord::IrreversibleMigration
  end
end
