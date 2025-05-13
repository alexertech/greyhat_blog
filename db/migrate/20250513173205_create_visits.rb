# frozen_string_literal: true

class CreateVisits < ActiveRecord::Migration[7.2]
  def change
    create_table :visits do |t|
      t.integer :visitable_id
      t.string :visitable_type
      t.string :ip_address
      t.string :user_agent
      t.string :referer
      t.datetime :viewed_at, default: -> { 'CURRENT_TIMESTAMP' }

      t.timestamps
    end
    
    add_index :visits, [:visitable_id, :visitable_type]
    add_index :visits, :viewed_at
  end
end
