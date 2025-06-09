class UpdateExistingVisitsActionType < ActiveRecord::Migration[7.2]
  def up
    # Set all existing visits to page_view (0) as default
    execute "UPDATE visits SET action_type = 0 WHERE action_type IS NULL"
    
    # Add default value for future records
    change_column_default :visits, :action_type, 0
  end

  def down
    change_column_default :visits, :action_type, nil
  end
end
