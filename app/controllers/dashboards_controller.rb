# frozen_string_literal: true

class DashboardsController < ApplicationController
  before_action :authenticate_user!

  def index
    # Core metrics
    @total_visits = Visit.count
    @visits_today = Visit.where('viewed_at >= ?', Time.zone.now.beginning_of_day).count
    @visits_this_week = Visit.where('viewed_at >= ?', 1.week.ago).count
    @visits_this_month = Visit.where('viewed_at >= ?', 1.month.ago).count
    @most_visited_posts = Post.most_visited(5)
    
    # Content metrics
    @total_posts = Post.count
    @published_posts = Post.published.count
    @draft_posts = Post.drafts.count
    @posts_this_month = Post.where('created_at >= ?', 1.month.ago).count
    
    # Engagement metrics
    @comment_count = Comment.count
    @pending_comment_count = Comment.pending.count
    @approved_comment_count = Comment.approved.count
    @comments_this_month = Comment.where('created_at >= ?', 1.month.ago).count
    
    # Traffic source metrics
    @social_media_visits = count_social_media_visits
    @search_engine_visits = count_search_engine_visits
    @direct_visits = Visit.where(referer: [nil, '']).count
    @referral_visits = @total_visits - @social_media_visits - @search_engine_visits - @direct_visits
    
    # Charts data
    @daily_visits_chart = Visit.count_by_date(30)
    @hourly_visits_chart = Visit.count_by_hour
    
    # Legacy variables for tests
    @home_visits = Visit.joins("JOIN pages ON visits.visitable_id = pages.id")
                       .where("visits.visitable_type = 'Page' AND pages.name = 'index'")
                       .count
    @posts_visits = Visit.where(visitable_type: 'Post').count
    
    # Popular search terms
    @popular_search_terms = extract_popular_search_terms
    
    # Device/Browser analytics
    @user_agents_summary = analyze_user_agents
    
    # Top referrers for quick view
    @top_referrers_preview = analyze_referrers(
      Visit.where.not(referer: [nil, ''])
           .group(:referer)
           .order('count_all DESC')
           .limit(5)
           .count
    )
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

  def extract_popular_search_terms
    # Extract search terms from Google referrers
    search_referrers = Visit.where("referer ILIKE '%google%' AND referer ILIKE '%q=%'")
                            .pluck(:referer)
    
    search_terms = {}
    search_referrers.each do |referer|
      begin
        uri = URI.parse(referer)
        params = CGI.parse(uri.query || '')
        query = params['q']&.first || params['query']&.first
        
        if query.present?
          term = query.downcase.strip
          search_terms[term] = (search_terms[term] || 0) + 1
        end
      rescue URI::InvalidURIError, StandardError
        # Skip invalid URIs
      end
    end
    
    # Also check for search within site
    internal_searches = Visit.joins("JOIN pages ON visits.visitable_id = pages.id")
                             .where("visits.visitable_type = 'Page' AND visits.referer ILIKE '%/buscar%'")
                             .count
    
    search_terms['búsqueda interna'] = internal_searches if internal_searches > 0
    
    search_terms.sort_by { |_, count| -count }.first(10).to_h
  end

  def analyze_user_agents
    user_agents = Visit.where.not(user_agent: [nil, ''])
                       .group(:user_agent)
                       .limit(100)
                       .count

    browsers = {}
    devices = {}
    os_systems = {}

    user_agents.each do |ua, count|
      # Simple browser detection
      case ua.downcase
      when /chrome/
        browsers['Chrome'] = (browsers['Chrome'] || 0) + count
      when /firefox/
        browsers['Firefox'] = (browsers['Firefox'] || 0) + count
      when /safari/
        browsers['Safari'] = (browsers['Safari'] || 0) + count
      when /edge/
        browsers['Edge'] = (browsers['Edge'] || 0) + count
      else
        browsers['Other'] = (browsers['Other'] || 0) + count
      end

      # Device detection
      case ua.downcase
      when /mobile|android|iphone/
        devices['Mobile'] = (devices['Mobile'] || 0) + count
      when /tablet|ipad/
        devices['Tablet'] = (devices['Tablet'] || 0) + count
      else
        devices['Desktop'] = (devices['Desktop'] || 0) + count
      end

      # OS detection
      case ua.downcase
      when /windows/
        os_systems['Windows'] = (os_systems['Windows'] || 0) + count
      when /mac os|macintosh/
        os_systems['macOS'] = (os_systems['macOS'] || 0) + count
      when /linux/
        os_systems['Linux'] = (os_systems['Linux'] || 0) + count
      when /android/
        os_systems['Android'] = (os_systems['Android'] || 0) + count
      when /ios|iphone|ipad/
        os_systems['iOS'] = (os_systems['iOS'] || 0) + count
      else
        os_systems['Other'] = (os_systems['Other'] || 0) + count
      end
    end

    {
      browsers: browsers.sort_by { |_, count| -count }.first(5).to_h,
      devices: devices.sort_by { |_, count| -count }.to_h,
      operating_systems: os_systems.sort_by { |_, count| -count }.first(5).to_h
    }
  end
end
