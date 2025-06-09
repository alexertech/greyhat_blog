class AddActionTypeToVisits < ActiveRecord::Migration[7.2]
  def change
    add_column :visits, :action_type, :integer
    add_column :visits, :session_id, :string
  end
end
