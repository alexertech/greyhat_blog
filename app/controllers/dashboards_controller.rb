# frozen_string_literal: true

class DashboardsController < ApplicationController
  before_action :authenticate_user!

  def index
    # Core metrics
    @total_visits = Visit.count
    @visits_today = Visit.where('viewed_at >= ?', Time.zone.now.beginning_of_day).count
    @visits_this_week = Visit.where('viewed_at >= ?', 1.week.ago).count
    @visits_this_month = Visit.where('viewed_at >= ?', 1.month.ago).count
    
    # Content Performance - Optimized queries
    @most_visited_posts = Post.most_visited(5)
    begin
      # Use database-level operations instead of loading all posts into memory
      @top_performing_posts = Post.published
                                 .joins('LEFT JOIN visits ON visits.visitable_id = posts.id AND visits.visitable_type = "Post"')
                                 .joins('LEFT JOIN comments ON comments.commentable_id = posts.id AND comments.commentable_type = "Post" AND comments.approved = true')
                                 .select('posts.*, COUNT(DISTINCT visits.id) as visit_count, COUNT(DISTINCT comments.id) as comment_count')
                                 .group('posts.id')
                                 .order('(COUNT(DISTINCT visits.id) * 0.6 + COUNT(DISTINCT comments.id) * 0.4) DESC')
                                 .limit(5)
      
      # Simplified trending calculation - posts with recent high activity
      @trending_posts = Post.published
                           .joins('JOIN visits ON visits.visitable_id = posts.id AND visits.visitable_type = "Post"')
                           .where('visits.viewed_at >= ?', 7.days.ago)
                           .group('posts.id')
                           .order('COUNT(visits.id) DESC')
                           .limit(3)
    rescue => e
      @top_performing_posts = []
      @trending_posts = []
    end

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

    # Newsletter Conversion Funnel
    begin
      @funnel_data = Visit.funnel_analysis(7)
      @newsletter_conversion_rate = Visit.newsletter_conversion_rate(7)
    rescue => e
      @funnel_data = {
        index_visits: 0, article_visits: 0, newsletter_page_visits: 0, 
        newsletter_clicks: 0, index_to_articles: 0, articles_to_newsletter: 0, 
        newsletter_conversion: 0
      }
      @newsletter_conversion_rate = 0
    end
    
    # Site Health Monitoring
    begin
      @site_health = SiteHealth.health_status
      @traffic_anomaly = SiteHealth.traffic_anomaly_detection
    rescue => e
      @site_health = { status: 'unknown', uptime: 0, avg_response_time: 0, error_count: 0, last_check: nil }
      @traffic_anomaly = { current_hour_visits: 0, average_hourly: 0, is_anomaly: false, threshold: 0 }
    end
    
    # Legacy variables for tests
    @home_visits = Visit.joins('JOIN pages ON visits.visitable_id = pages.id')
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

    # Performance Analytics
    @bounce_rate = calculate_bounce_rate
    @avg_session_duration = calculate_avg_session_duration
    @top_exit_pages = find_top_exit_pages
    @conversion_funnel = analyze_conversion_funnel

    # Live Activity (last 24 hours)
    @recent_visits = Visit.includes(:visitable)
                          .where('viewed_at >= ?', 24.hours.ago)
                          .order(viewed_at: :desc)
                          .limit(20)

    # Performance insights
    @insights = generate_performance_insights
    
    # Content Strategy Insights
    begin
      @content_insights = generate_content_insights
      @tag_performance = analyze_tag_performance
    rescue => e
      @content_insights = ['Datos insuficientes para generar insights']
      @tag_performance = {}
    end
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

    Visit.where('referer ILIKE ANY (ARRAY[?])', social_domains.map { |domain| "%#{domain}%" }).count
  end

  def count_search_engine_visits
    search_domains = %w[google. bing.com duckduckgo.com yahoo.com]

    Visit.where('referer ILIKE ANY (ARRAY[?])', search_domains.map { |domain| "%#{domain}%" }).count
  end

  def extract_popular_search_terms
    # Extract search terms from Google referrers
    search_referrers = Visit.where("referer ILIKE '%google%' AND referer ILIKE '%q=%'")
                            .pluck(:referer)

    search_terms = {}
    search_referrers.each do |referer|
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

    # Also check for search within site
    internal_searches = Visit.joins('JOIN pages ON visits.visitable_id = pages.id')
                             .where("visits.visitable_type = 'Page' AND visits.referer ILIKE '%/buscar%'")
                             .count

    search_terms['búsqueda interna'] = internal_searches if internal_searches.positive?

    search_terms.sort_by { |_, count| -count }.first(10).to_h
  end

  def analyze_user_agents
    # Use database aggregation instead of loading all user agents into memory
    browsers = {
      'Chrome' => Visit.where("user_agent ILIKE '%chrome%' AND user_agent NOT ILIKE '%edge%'").count,
      'Firefox' => Visit.where("user_agent ILIKE '%firefox%'").count,
      'Safari' => Visit.where("user_agent ILIKE '%safari%' AND user_agent NOT ILIKE '%chrome%'").count,
      'Edge' => Visit.where("user_agent ILIKE '%edge%'").count
    }
    browsers['Other'] = Visit.where.not(user_agent: [nil, '']).count - browsers.values.sum
    
    devices = {
      'Mobile' => Visit.where("user_agent ILIKE ANY (ARRAY['%mobile%', '%android%', '%iphone%'])").count,
      'Tablet' => Visit.where("user_agent ILIKE ANY (ARRAY['%tablet%', '%ipad%'])").count
    }
    devices['Desktop'] = Visit.where.not(user_agent: [nil, '']).count - devices.values.sum
    
    os_systems = {
      'Windows' => Visit.where("user_agent ILIKE '%windows%'").count,
      'macOS' => Visit.where("user_agent ILIKE ANY (ARRAY['%mac os%', '%macintosh%'])").count,
      'Linux' => Visit.where("user_agent ILIKE '%linux%'").count,
      'Android' => Visit.where("user_agent ILIKE '%android%'").count,
      'iOS' => Visit.where("user_agent ILIKE ANY (ARRAY['%ios%', '%iphone%', '%ipad%'])").count
    }
    os_systems['Other'] = Visit.where.not(user_agent: [nil, '']).count - os_systems.values.sum

    return {
      browsers: browsers.select { |_, count| count > 0 }.sort_by { |_, count| -count }.first(5).to_h,
      devices: devices.select { |_, count| count > 0 }.sort_by { |_, count| -count }.to_h,
      operating_systems: os_systems.select { |_, count| count > 0 }.sort_by { |_, count| -count }.first(5).to_h
    }
    
    # Legacy code removed - no longer needed
    user_agents = {}
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

  # Performance Analytics Methods
  def calculate_bounce_rate
    # Single page sessions / total sessions * 100
    # For simplicity, we'll consider visits that lasted less than 30 seconds as bounces
    total_visits = Visit.count
    return 0 if total_visits.zero?

    # This is a simplified bounce rate calculation
    # In a real scenario, you'd track session duration properly
    recent_visits = Visit.where('viewed_at >= ?', 1.month.ago).count
    return 0 if recent_visits.zero?

    # Estimate bounce rate based on single-page visits from same IP within short timeframe
    bounces = Visit.where('viewed_at >= ?', 1.month.ago)
                   .group(:ip_address)
                   .having('COUNT(*) = 1')
                   .count
                   .size

    ((bounces.to_f / recent_visits) * 100).round(1)
  end

  def calculate_avg_session_duration
    # This is a simplified calculation
    # In production, you'd want to track actual session data
    total_visits = Visit.where('viewed_at >= ?', 1.week.ago).count
    return 0 if total_visits.zero?

    # Simple heuristic: more page views per visitor = longer sessions
    unique_visitors = Visit.where('viewed_at >= ?', 1.week.ago)
                           .distinct
                           .count(:ip_address)

    return 0 if unique_visitors.zero?

    avg_pages_per_visitor = total_visits.to_f / unique_visitors

    # Estimate 1-2 minutes per page view
    (avg_pages_per_visitor * 90).round # seconds
  end

  def find_top_exit_pages
    # Simplified exit pages calculation using Rails queries instead of raw SQL
    exit_pages = {}

    begin
      # Get the most commonly visited page types as exit pages
      Visit.where('viewed_at >= ?', 1.week.ago)
           .group(:visitable_type)
           .order('COUNT(*) DESC')
           .limit(10)
           .count
           .each do |visitable_type, count|
             exit_pages[visitable_type] = count
           end
    rescue => e
      Rails.logger.error "Error calculating exit pages: #{e.message}"
      exit_pages = { 'Post' => 0, 'Page' => 0 }
    end

    exit_pages
  end

  def analyze_conversion_funnel
    # Simple conversion funnel: Home → Post → Contact
    total_visitors = Visit.distinct.count(:ip_address)
    return {} if total_visitors.zero?

    # Visitors who viewed home page
    home_visitors = Visit.joins('JOIN pages ON visits.visitable_id = pages.id')
                         .where("visits.visitable_type = 'Page' AND pages.name = 'index'")
                         .distinct
                         .count(:ip_address)

    # Visitors who viewed any post
    post_visitors = Visit.where(visitable_type: 'Post')
                         .distinct
                         .count(:ip_address)

    # Visitors who contacted
    contact_visitors = Visit.joins('JOIN pages ON visits.visitable_id = pages.id')
                            .where("visits.visitable_type = 'Page' AND pages.name = 'contact'")
                            .distinct
                            .count(:ip_address)

    {
      'Total Visitantes' => total_visitors,
      'Vieron Inicio' => home_visitors,
      'Leyeron Artículos' => post_visitors,
      'Visitaron Contacto' => contact_visitors,
      'Conversión a Artículos' => total_visitors.positive? ? "#{((post_visitors.to_f / total_visitors) * 100).round(1)}%" : '0%',
      'Conversión a Contacto' => total_visitors.positive? ? "#{((contact_visitors.to_f / total_visitors) * 100).round(1)}%" : '0%'
    }
  end

  def generate_performance_insights
    insights = []

    # Traffic growth insight
    current_week = Visit.where('viewed_at >= ?', 1.week.ago).count
    previous_week = Visit.where('viewed_at >= ? AND viewed_at < ?', 2.weeks.ago, 1.week.ago).count

    if previous_week.positive?
      growth = ((current_week - previous_week).to_f / previous_week * 100).round(1)
      if growth.positive?
        insights << "Tu tráfico aumentó #{growth}% esta semana"
      elsif growth.negative?
        insights << "Tu tráfico disminuyó #{growth.abs}% esta semana"
      end
    end

    # Top traffic source insight
    if @social_media_visits > @search_engine_visits && @social_media_visits > @direct_visits
      social_percentage = ((@social_media_visits.to_f / Visit.count) * 100).round
      insights << "Las redes sociales generan el #{social_percentage}% de tu tráfico"
    elsif @search_engine_visits > @direct_visits
      search_percentage = ((@search_engine_visits.to_f / Visit.count) * 100).round
      insights << "Los buscadores generan el #{search_percentage}% de tu tráfico"
    end

    # Popular content insight
    most_visited = Post.most_visited(1).first
    if most_visited && most_visited.visits.count > 10
      insights << "Tu artículo más popular es '#{most_visited.title.truncate(40)}'"
    end

    # Recent activity insight
    today_visits = Visit.where('viewed_at >= ?', Time.zone.now.beginning_of_day).count
    insights << "Has tenido #{today_visits} visitas hoy" if today_visits.positive?

    insights.presence || ['¡Sigue creando contenido increíble!']
  end

  def generate_content_insights
    insights = []

    # Best performing content type
    if Post.published.any?
      top_tag = Tag.joins(:posts)
                   .joins("JOIN visits ON visits.visitable_id = posts.id AND visits.visitable_type = 'Post'")
                   .group('tags.name')
                   .order('COUNT(visits.id) DESC')
                   .first

      if top_tag
        insights << "Contenido sobre '#{top_tag.name}' genera más engagement"
      end

      # Publishing timing insights
      best_day = Visit.joins("JOIN posts ON visits.visitable_id = posts.id")
                     .where(visitable_type: 'Post')
                     .where('posts.created_at >= ?', 30.days.ago)
                     .group("EXTRACT(DOW FROM posts.created_at)")
                     .order('COUNT(*) DESC')
                     .first

      if best_day
        day_name = Date::DAYNAMES[best_day[0].to_i]
        insights << "Los #{day_name}s son tu mejor día para publicar"
      end

      # Newsletter conversion insights
      conversion_rate = Visit.newsletter_conversion_rate(30)
      if conversion_rate > 5
        insights << "Excelente tasa de conversión a newsletter: #{conversion_rate}%"
      elsif conversion_rate > 0
        insights << "Tasa de conversión a newsletter: #{conversion_rate}% - ¡mejorable!"
      end
    end

    insights.presence || ['Publica más contenido para generar insights']
  end

  def analyze_tag_performance
    return {} unless Post.published.any?

    Tag.joins(:posts)
       .joins("JOIN visits ON visits.visitable_id = posts.id AND visits.visitable_type = 'Post'")
       .group('tags.name')
       .order('COUNT(visits.id) DESC')
       .limit(10)
       .count
  end
end
