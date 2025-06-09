class CreateSiteHealths < ActiveRecord::Migration[7.2]
  def change
    create_table :site_healths do |t|
      t.string :metric_type, null: false
      t.decimal :value, precision: 10, scale: 2, null: false
      t.text :metadata
      t.datetime :checked_at, null: false

      t.timestamps
    end

    add_index :site_healths, :metric_type
    add_index :site_healths, :checked_at
    add_index :site_healths, [:metric_type, :checked_at]
  end
end
