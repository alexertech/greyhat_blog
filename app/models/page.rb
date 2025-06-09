# frozen_string_literal: true

class Page < ApplicationRecord
  has_many :visits, as: :visitable, dependent: :destroy

  def recent_visits(days = 7)
    visits.where('viewed_at >= ?', days.days.ago).count
  end

  def self.visits_by_day(days = 7)
    page_ids = pluck(:id)
    return {} if page_ids.empty?

    Visit.where(visitable_type: 'Page', visitable_id: page_ids)
         .where('viewed_at >= ?', days.days.ago)
         .group('DATE(viewed_at)')
         .order('DATE(viewed_at)')
         .count
  end
end
