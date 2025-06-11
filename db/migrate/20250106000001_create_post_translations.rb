# frozen_string_literal: true

class CreatePostTranslations < ActiveRecord::Migration[7.2]
  def change
    create_table :post_translations do |t|
      t.references :post, null: false, foreign_key: true
      t.string :locale, null: false, limit: 5
      t.string :title, null: false
      t.text :body
      t.string :slug, null: false
      t.boolean :published, default: false
      
      t.timestamps
    end
    
    add_index :post_translations, [:post_id, :locale], unique: true
    add_index :post_translations, :slug, unique: true
    add_index :post_translations, :locale
    add_index :post_translations, :published
  end
end