class AddUniqueVisitsToBlogPosts < ActiveRecord::Migration[7.0]
  def change
    add_column :posts, :unique_visits, :integer, default: 0
  end
end
