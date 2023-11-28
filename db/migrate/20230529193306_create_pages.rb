# frozen_string_literal: true

class CreatePages < ActiveRecord::Migration[7.0]
  def change
    create_table :pages do |t|
      t.string :name
      t.integer :unique_visits, default: 0

      t.timestamps
    end
  end
end
