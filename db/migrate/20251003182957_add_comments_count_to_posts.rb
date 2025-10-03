class AddCommentsCountToPosts < ActiveRecord::Migration[7.2]
  def change
    add_column :posts, :comments_count, :integer, default: 0, null: false
    add_column :posts, :approved_comments_count, :integer, default: 0, null: false

    # Backfill existing counts
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE posts
          SET comments_count = (
            SELECT COUNT(*)
            FROM comments
            WHERE comments.post_id = posts.id
          ),
          approved_comments_count = (
            SELECT COUNT(*)
            FROM comments
            WHERE comments.post_id = posts.id AND comments.approved = true
          )
        SQL
      end
    end
  end
end
