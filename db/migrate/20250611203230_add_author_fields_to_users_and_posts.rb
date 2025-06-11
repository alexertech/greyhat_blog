class AddAuthorFieldsToUsersAndPosts < ActiveRecord::Migration[7.2]
  def change
    # Add author fields to users table
    add_column :users, :public_name, :string
    add_column :users, :description, :text
    
    # Add user_id to posts table
    add_reference :posts, :user, null: true, foreign_key: true
    
    # Set default user_id to 1 for existing posts
    reversible do |dir|
      dir.up do
        # Update existing posts to belong to user with ID 1
        execute "UPDATE posts SET user_id = 1 WHERE user_id IS NULL"
        
        # Make user_id not null after setting default values
        change_column_null :posts, :user_id, false
      end
      
      dir.down do
        # Allow nulls again when rolling back
        change_column_null :posts, :user_id, true
      end
    end
  end
end
