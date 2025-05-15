class AddApprovedToComments < ActiveRecord::Migration[7.2]
  def change
    add_column :comments, :approved, :boolean, default: false, null: false
    add_index :comments, :approved
  end
end
