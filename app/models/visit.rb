# frozen_string_literal: true

class Visit < ApplicationRecord
  belongs_to :visitable, polymorphic: true

  validates :visitable, presence: true
  validates :ip_address, presence: true

  before_create :set_viewed_at

  scope :last_week, -> { where('viewed_at >= ?', 1.week.ago) }
  scope :last_month, -> { where('viewed_at >= ?', 1.month.ago) }
  scope :this_year, -> { where('viewed_at >= ?', Time.zone.now.beginning_of_year) }
  scope :bots, lambda {
    where("user_agent ILIKE ANY (ARRAY['%bot%', '%crawler%', '%spider%', '%yahoo%', '%slurp%', '%daum%', '%yandex%', '%googlebot%', '%bingbot%', '%baiduspider%', '%twitterbot%', '%facebookexternalhit%', '%rogerbot%', '%linkedinbot%', '%embedly%', '%quora%', '%pinterest%', '%slackbot%', '%redditbot%', '%snapchat%', '%applebot%'])")
  }
  scope :humans, lambda {
    where.not("user_agent ILIKE ANY (ARRAY['%bot%', '%crawler%', '%spider%', '%yahoo%', '%slurp%', '%daum%', '%yandex%', '%googlebot%', '%bingbot%', '%baiduspider%', '%twitterbot%', '%facebookexternalhit%', '%rogerbot%', '%linkedinbot%', '%embedly%', '%quora%', '%pinterest%', '%slackbot%', '%redditbot%', '%snapchat%', '%applebot%'])")
  }

  def self.count_by_date(period = 7)
    where('viewed_at >= ?', period.days.ago)
      .group(Arel.sql('DATE(viewed_at)'))
      .order(Arel.sql('DATE(viewed_at)'))
      .count
  end

  def self.count_by_hour
    where('viewed_at >= ?', 24.hours.ago)
      .group(Arel.sql('EXTRACT(HOUR FROM viewed_at)::integer'))
      .order(Arel.sql('EXTRACT(HOUR FROM viewed_at)::integer'))
      .count
  end

  def bot?
    return false if user_agent.blank?

    user_agent.downcase.match?(/(bot|crawler|spider|yahoo|slurp|daum|yandex|googlebot|bingbot|baiduspider|twitterbot|facebookexternalhit|rogerbot|linkedinbot|embedly|quora|pinterest|slackbot|redditbot|snapchat|applebot)/i)
  end

  private

  def set_viewed_at
    self.viewed_at ||= Time.zone.now
  end
end
