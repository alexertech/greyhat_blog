# frozen_string_literal: true

class Visit < ApplicationRecord
  belongs_to :visitable, polymorphic: true

  validates :visitable, presence: true
  validates :ip_address, presence: true

  before_create :set_viewed_at

  enum action_type: {
    page_view: 0,
    newsletter_click: 1,
    external_link: 2
  }, _default: 0

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

  def self.newsletter_conversion_rate(days = 7)
    total_article_visits = where(visitable_type: 'Post')
                          .where('viewed_at >= ?', days.days.ago)
                          .humans
                          .count

    newsletter_clicks = where(action_type: 'newsletter_click')
                       .where('viewed_at >= ?', days.days.ago)
                       .count

    return 0 if total_article_visits.zero?
    
    (newsletter_clicks.to_f / total_article_visits * 100).round(2)
  end

  def self.funnel_analysis(days = 7)
    base_scope = where('viewed_at >= ?', days.days.ago).humans

    index_visits = base_scope.where(visitable_type: 'Page', visitable_id: 1).count
    article_visits = base_scope.where(visitable_type: 'Post').count
    newsletter_page_visits = base_scope.where(visitable_type: 'Page', visitable_id: 5).count
    newsletter_clicks = base_scope.where(action_type: 'newsletter_click').count

    {
      index_visits: index_visits,
      article_visits: article_visits,
      newsletter_page_visits: newsletter_page_visits,
      newsletter_clicks: newsletter_clicks,
      index_to_articles: index_visits > 0 ? (article_visits.to_f / index_visits * 100).round(1) : 0,
      articles_to_newsletter: article_visits > 0 ? (newsletter_page_visits.to_f / article_visits * 100).round(1) : 0,
      newsletter_conversion: newsletter_page_visits > 0 ? (newsletter_clicks.to_f / newsletter_page_visits * 100).round(1) : 0
    }
  end

  private

  def set_viewed_at
    self.viewed_at ||= Time.zone.now
  end
end
