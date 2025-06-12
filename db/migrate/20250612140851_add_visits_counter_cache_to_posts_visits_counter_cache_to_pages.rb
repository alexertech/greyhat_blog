# frozen_string_literal: true

class AddVisitsCounterCacheToPostsVisitsCounterCacheToPages < ActiveRecord::Migration[7.2]
  def change
    # Add visits_count counter cache to posts table
    add_column :posts, :visits_count, :integer, default: 0, null: false
    
    # Add visits_count counter cache to pages table  
    add_column :pages, :visits_count, :integer, default: 0, null: false
    
    # Add index on the counter cache columns for performance
    add_index :posts, :visits_count
    add_index :pages, :visits_count
    
    # Populate initial values for existing records
    reversible do |dir|
      dir.up do
        # Update posts with their current visit counts
        execute <<-SQL
          UPDATE posts 
          SET visits_count = (
            SELECT COUNT(*) 
            FROM visits 
            WHERE visits.visitable_type = 'Post' 
            AND visits.visitable_id = posts.id
          )
        SQL
        
        # Update pages with their current visit counts
        execute <<-SQL
          UPDATE pages 
          SET visits_count = (
            SELECT COUNT(*) 
            FROM visits 
            WHERE visits.visitable_type = 'Page' 
            AND visits.visitable_id = pages.id
          )
        SQL
      end
    end
  end
end