# frozen_string_literal: true

# Visitable concern for models that can receive visits
# Provides common analytics query methods for visitables (Post, Page, etc.)
#
# Usage:
#   class Post < ApplicationRecord
#     include Visitable
#   end
module Visitable
  extend ActiveSupport::Concern

  included do
    has_many :visits, as: :visitable, dependent: :destroy
  end

  # Instance methods for individual visitable records
  def recent_visits(days = 7)
    visits.where('viewed_at >= ?', days.days.ago).count
  end

  # Class methods for collections of visitable records
  class_methods do
    # Returns visits grouped by date for the specified period
    # @param days [Integer] number of days to look back (default: 7)
    # @return [Hash] hash with dates as keys and visit counts as values
    #
    # Example:
    #   Post.visits_by_day(7)
    #   => { "2025-09-29" => 45, "2025-09-30" => 52, ... }
    def visits_by_day(days = 7)
      ids = pluck(:id)
      return {} if ids.empty?

      Visit.where(visitable_type: name, visitable_id: ids)
           .where('viewed_at >= ?', days.days.ago)
           .group('DATE(viewed_at)')
           .order('DATE(viewed_at)')
           .count
    end
  end
end
