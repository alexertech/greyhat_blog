class CreateComments < ActiveRecord::Migration[7.2]
  def change
    create_table :comments do |t|
      t.references :post, null: false, foreign_key: true
      t.string :username, null: false
      t.string :email, null: false
      t.text :body, null: false, limit: 140

      t.timestamps
    end
    
    add_index :comments, :created_at
  end
end
