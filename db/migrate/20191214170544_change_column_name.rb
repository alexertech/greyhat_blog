class ChangeColumnName < ActiveRecord::Migration[6.0]
  def change
    rename_column :posts, :posts, :body
  end
end
