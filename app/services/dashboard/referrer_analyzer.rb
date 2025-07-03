# frozen_string_literal: true

class Dashboard::ReferrerAnalyzer
  SOCIAL_DOMAINS = %w[linkedin.com substack.com twitter.com x.com facebook.com instagram.com tiktok.com].freeze
  SEARCH_DOMAINS = %w[google. bing.com duckduckgo.com yahoo.com].freeze
  TECH_COMMUNITY_DOMAINS = %w[github.com stackoverflow.com dev.to].freeze
  BLOG_PLATFORM_DOMAINS = %w[medium.com hackernoon.com].freeze

  def self.analyze(referrer_counts)
    referrer_counts.map do |referer, count|
      new(referer, count).analysis
    end
  end

  attr_reader :referer, :count

  def initialize(referer, count)
    @referer = referer
    @count = count
  end

  def analysis
    {
      url: referer,
      count: count,
      domain: domain,
      source_type: source_type,
      display_name: display_name
    }
  end

  def domain
    return 'Direct' if referer.blank?

    @domain ||= begin
      URI.parse(referer).host&.downcase&.gsub(/^www\./, '') || 'Unknown'
    rescue URI::InvalidURIError
      'Unknown'
    end
  end

  def source_type
    return :direct if referer.blank?

    case domain
    when *SOCIAL_DOMAINS
      :social
    when *SEARCH_DOMAINS
      :search
    when *TECH_COMMUNITY_DOMAINS
      :tech_community
    when *BLOG_PLATFORM_DOMAINS
      :blog_platform
    else
      :other
    end
  end

  def display_name
    return 'Directo' if referer.blank?

    case domain
    when 'linkedin.com' then 'LinkedIn'
    when 'substack.com' then 'Substack'
    when 'twitter.com', 'x.com' then 'Twitter/X'
    when 'facebook.com' then 'Facebook'
    when 'instagram.com' then 'Instagram'
    when 'google.com', 'google.es' then 'Google'
    when 'github.com' then 'GitHub'
    when 'stackoverflow.com' then 'Stack Overflow'
    when 'dev.to' then 'DEV Community'
    when 'medium.com' then 'Medium'
    else
      domain&.humanize || 'Desconocido'
    end
  end
end
