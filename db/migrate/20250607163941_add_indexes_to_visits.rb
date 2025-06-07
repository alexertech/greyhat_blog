# frozen_string_literal: true

class AddIndexesToVisits < ActiveRecord::Migration[7.2]
  def change
    # Index for IP-based uniqueness checking
    add_index :visits, %i[visitable_type visitable_id ip_address viewed_at],
              name: 'index_visits_on_unique_check'

    # Index for time-based queries
    add_index :visits, %i[ip_address viewed_at]
  end
end
