# frozen_string_literal: true

class AddPerformanceIndexes < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!
  
  def change
    # Critical index for slug lookups in PostsController (if not exists)
    add_index :posts, :slug, algorithm: :concurrently unless index_exists?(:posts, :slug)

    # Composite index for published posts ordering
    add_index :posts, [:draft, :created_at], where: "draft = false", algorithm: :concurrently unless index_exists?(:posts, [:draft, :created_at])

    # Index for visit action type filtering (newsletter analytics)
    add_index :visits, :action_type, algorithm: :concurrently unless index_exists?(:visits, :action_type)

    # Index for IP address lookups (if not exists)
    add_index :visits, :ip_address, algorithm: :concurrently unless index_exists?(:visits, :ip_address)

    # Index for user agent bot filtering (new one)
    add_index :visits, :user_agent, algorithm: :concurrently unless index_exists?(:visits, :user_agent)

    # Index for approved comments count (post-specific)
    add_index :comments, [:post_id, :approved], 
              name: 'idx_comments_post_approved', algorithm: :concurrently unless index_exists?(:comments, [:post_id, :approved])
  end
end