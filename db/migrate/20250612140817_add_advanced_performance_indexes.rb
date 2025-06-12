# frozen_string_literal: true

class AddAdvancedPerformanceIndexes < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!
  
  def change
    # Enable pg_trgm extension for advanced text search
    enable_extension 'pg_trgm' unless extension_enabled?('pg_trgm')
    
    # Critical index for newsletter conversion tracking
    # This optimizes the complex self-join query in Post#newsletter_conversions
    add_index :visits, [:action_type, :visitable_type, :visitable_id, :ip_address, :viewed_at], 
              where: "action_type = 1", 
              name: 'idx_visits_newsletter_conversion',
              algorithm: :concurrently
    
    # Index for post visit counting optimization (Post.most_visited)
    add_index :visits, [:visitable_type, :visitable_id], 
              where: "visitable_type = 'Post'",
              name: 'idx_visits_post_count',
              algorithm: :concurrently
              
    # GIN index for user agent pattern matching (dashboard analytics)
    add_index :visits, :user_agent, 
              using: :gin, 
              opclass: :gin_trgm_ops,
              name: 'idx_visits_user_agent_gin',
              algorithm: :concurrently
              
    # Composite index for tag-based post searches (related_posts)
    add_index :post_tags, [:tag_id, :post_id],
              name: 'idx_post_tags_lookup',
              algorithm: :concurrently
              
    # Index for post conversion tracking lookups
    add_index :visits, [:visitable_type, :visitable_id, :ip_address, :viewed_at],
              where: "visitable_type = 'Post'",
              name: 'idx_visits_post_conversion',
              algorithm: :concurrently
              
    # Function-based index for hour extraction (site health analytics)
    add_index :visits, 'EXTRACT(HOUR FROM viewed_at), viewed_at',
              name: 'idx_visits_hour_extract',
              algorithm: :concurrently
              
    # Index for page name lookups (funnel analysis)
    add_index :pages, :name,
              name: 'idx_pages_name',
              algorithm: :concurrently
              
    # Composite index for time-based visit analysis
    add_index :visits, [:ip_address, :viewed_at],
              name: 'idx_visits_ip_time',
              algorithm: :concurrently unless index_exists?(:visits, [:ip_address, :viewed_at])
  end
  
  def down
    remove_index :visits, name: 'idx_visits_newsletter_conversion'
    remove_index :visits, name: 'idx_visits_post_count'
    remove_index :visits, name: 'idx_visits_user_agent_gin'
    remove_index :post_tags, name: 'idx_post_tags_lookup'
    remove_index :visits, name: 'idx_visits_post_conversion'
    remove_index :visits, name: 'idx_visits_hour_extract'
    remove_index :pages, name: 'idx_pages_name'
    remove_index :visits, name: 'idx_visits_ip_time' if index_exists?(:visits, name: 'idx_visits_ip_time')
  end
end