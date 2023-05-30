class Page < ApplicationRecord

  def self.total_unique_visits
    sum { |record| record.unique_visits }
  end
  
end
