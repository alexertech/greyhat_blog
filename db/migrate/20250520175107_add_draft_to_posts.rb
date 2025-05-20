class AddDraftToPosts < ActiveRecord::Migration[7.2]
  def change
    add_column :posts, :draft, :boolean, default: false, null: false
    
    # Update existing posts to not be drafts
    Post.update_all(draft: false) if defined?(Post)
  end
end
