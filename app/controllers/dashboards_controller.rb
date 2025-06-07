# frozen_string_literal: true

class DashboardsController < ApplicationController
  before_action :authenticate_user!

  def index
    @total_visits = Visit.count
    @visits_today = Visit.where('viewed_at >= ?', Time.zone.now.beginning_of_day).count
    @visits_this_week = Visit.where('viewed_at >= ?', 1.week.ago).count
    @most_visited_posts = Post.most_visited(5)
    
    # Visit counts by page - optimized to avoid N+1 queries
    pages_with_visits = Page.includes(:visits).where(id: [1, 2, 3]).index_by(&:id)
    @home_visits = pages_with_visits[1]&.visits&.size || 0
    @about_visits = pages_with_visits[2]&.visits&.size || 0
    @services_visits = pages_with_visits[3]&.visits&.size || 0
    @posts_visits = Visit.where(visitable_type: 'Post').count
    
    # Comment count for dashboard
    @comment_count = Comment.count
    @pending_comment_count = Comment.pending.count
  end

  def stats
    @period = params[:period].present? ? params[:period].to_i : 7
    
    @daily_visits = Visit.count_by_date(@period)
    @hourly_visits = Visit.count_by_hour
    @page_visits = Page.visits_by_day(@period)
    @post_visits = Post.visits_by_day(@period)
    
    @referrer_counts = Visit.where.not(referer: [nil, ''])
                            .group(:referer)
                            .order('count_all DESC')
                            .limit(10)
                            .count
    
    # Enhanced referrer analysis
    @top_referrers = analyze_referrers(@referrer_counts)
    @social_media_visits = count_social_media_visits
    @search_engine_visits = count_search_engine_visits
    @direct_visits = Visit.where(referer: [nil, '']).count
  end

  def posts
    @posts = Post.includes(:visits).order(created_at: :desc).paginate(page: params[:page], per_page: 10)
  end
  
  def comments
    comments = Comment.includes(:post).order(created_at: :desc)
    
    case params[:filter]
    when 'pending'
      comments = comments.pending
    when 'approved'
      comments = comments.approved
    end
    
    @comments = comments.paginate(page: params[:page], per_page: 20)
  end

  private

  def analyze_referrers(referrer_counts)
    referrer_counts.map do |referer, count|
      {
        url: referer,
        count: count,
        domain: extract_domain(referer),
        source_type: categorize_referrer(referer),
        display_name: format_referrer_name(referer)
      }
    end
  end

  def extract_domain(url)
    return 'Direct' if url.blank?
    
    begin
      URI.parse(url).host&.downcase&.gsub(/^www\./, '') || 'Unknown'
    rescue URI::InvalidURIError
      'Unknown'
    end
  end

  def categorize_referrer(url)
    return :direct if url.blank?
    
    domain = extract_domain(url)
    
    case domain
    when /linkedin\.com/
      :social
    when /substack\.com/
      :newsletter
    when /twitter\.com/, /x\.com/, /facebook\.com/, /instagram\.com/, /tiktok\.com/
      :social
    when /google\./, /bing\.com/, /duckduckgo\.com/, /yahoo\.com/
      :search
    when /github\.com/, /stackoverflow\.com/, /dev\.to/
      :tech_community
    when /medium\.com/, /hackernoon\.com/
      :blog_platform
    else
      :other
    end
  end

  def format_referrer_name(url)
    return 'Directo' if url.blank?
    
    domain = extract_domain(url)
    
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

  def count_social_media_visits
    social_domains = %w[linkedin.com substack.com twitter.com x.com facebook.com instagram.com tiktok.com]
    
    Visit.where("referer ILIKE ANY (ARRAY[?])", social_domains.map { |domain| "%#{domain}%" }).count
  end

  def count_search_engine_visits
    search_domains = %w[google. bing.com duckduckgo.com yahoo.com]
    
    Visit.where("referer ILIKE ANY (ARRAY[?])", search_domains.map { |domain| "%#{domain}%" }).count
  end
end
