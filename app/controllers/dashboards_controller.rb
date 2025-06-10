# frozen_string_literal: true

class DashboardsController < ApplicationController
  before_action :authenticate_user!

  def index
    # Core metrics - optimized with single query
    begin
      visits_stats = Visit.group(
        "CASE 
           WHEN viewed_at >= '#{Time.zone.now.beginning_of_day}' THEN 'today'
           WHEN viewed_at >= '#{1.week.ago}' THEN 'week'
           WHEN viewed_at >= '#{1.month.ago}' THEN 'month'
           ELSE 'total'
         END"
      ).count
      
      @total_visits = Visit.count
      @visits_today = visits_stats['today'] || 0
      @visits_this_week = visits_stats['week'] || 0
      @visits_this_month = visits_stats['month'] || 0
    rescue => e
      # Fallback to simple queries if optimized version fails
      Rails.logger.error "Dashboard optimization error: #{e.message}"
      @total_visits = Visit.count
      @visits_today = Visit.where('viewed_at >= ?', Time.zone.now.beginning_of_day).count
      @visits_this_week = Visit.where('viewed_at >= ?', 1.week.ago).count
      @visits_this_month = Visit.where('viewed_at >= ?', 1.month.ago).count
    end
    
    # Content Performance - Optimized queries with includes
    @most_visited_posts = Post.includes(:comments, :tags, :visits).most_visited(5)
    begin
      # Simplified approach for top performing posts based on visits
      @top_performing_posts = Post.published
                                 .includes(:comments, :tags, :visits)
                                 .left_joins(:visits)
                                 .group('posts.id')
                                 .order('COUNT(visits.id) DESC')
                                 .limit(5)
      
      # If no posts with visits, just get recent published posts
      if @top_performing_posts.empty? || @top_performing_posts.sum { |p| p.visits.count } == 0
        @top_performing_posts = Post.published.includes(:comments, :tags).order(created_at: :desc).limit(5)
      end
      
      # Simplified trending calculation - posts with recent high activity
      @trending_posts = Post.published
                           .includes(:comments, :tags, :visits)
                           .joins(:visits)
                           .where('visits.viewed_at >= ?', 7.days.ago)
                           .group('posts.id')
                           .order('COUNT(visits.id) DESC')
                           .limit(3)
                           
      # Fallback for trending posts
      if @trending_posts.empty?
        @trending_posts = Post.published.includes(:comments, :tags).order(created_at: :desc).limit(3)
      end
      
    rescue => e
      Rails.logger.error "Error calculating top performing posts: #{e.message}"
      @top_performing_posts = Post.published.includes(:comments, :tags).order(created_at: :desc).limit(5)
      @trending_posts = Post.published.includes(:comments, :tags).order(created_at: :desc).limit(3)
    end

    # Content metrics
    @total_posts = Post.count
    @published_posts = Post.published.count
    @draft_posts = Post.drafts.count
    @posts_this_month = Post.where('created_at >= ?', 1.month.ago).count

    # Engagement metrics - optimized with single query
    comment_stats = Comment.group(:approved).count
    comment_time_stats = Comment.group(
      "CASE WHEN created_at >= '#{1.month.ago}' THEN 'month' ELSE 'older' END"
    ).count
    
    @comment_count = Comment.count
    @pending_comment_count = comment_stats[false] || 0
    @approved_comment_count = comment_stats[true] || 0
    @comments_this_month = comment_time_stats['month'] || 0

    # Contact metrics
    @total_contacts = Contact.count
    @contacts_this_month = Contact.where('created_at >= ?', 1.month.ago).count

    # Traffic source metrics - improved calculation
    @social_media_visits = count_social_media_visits
    @search_engine_visits = count_search_engine_visits
    @direct_visits = Visit.where(referer: [nil, '']).count
    
    # Calculate referral visits more accurately
    total_categorized = @social_media_visits + @search_engine_visits + @direct_visits
    @referral_visits = [@total_visits - total_categorized, 0].max

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

    # Top referrers for quick view - exclude self-referrers
    @top_referrers_preview = analyze_referrers(
      Visit.where.not(referer: [nil, ''])
           .where.not("referer ILIKE '%greyhat.cl%'")
           .where.not("referer ILIKE '%localhost%'")
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
                            .where.not("referer ILIKE '%greyhat.cl%'")
                            .where.not("referer ILIKE '%localhost%'")
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
      Rails.logger.error "Error generating content insights: #{e.message}"
      @content_insights = ['Error generando insights - revisa los logs']
      @tag_performance = {}
    end
  end

  def posts
    # Optimized query to avoid N+1 problems and improve performance
    @posts = Post.includes(:visits, :tags)
                 .order(created_at: :desc)
                 .paginate(page: params[:page], per_page: 10)
    
    # Add visits_count as a method for each post to avoid N+1 issues
    @posts.each do |post|
      post.define_singleton_method(:visits_count) { post.visits.size }
    end
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
    search_terms = {}
    
    begin
      # Extract search terms from Google referrers with different parameter formats
      google_referrers = Visit.where("referer ILIKE '%google%' AND (referer ILIKE '%q=%' OR referer ILIKE '%query=%')")
                              .pluck(:referer)

      google_referrers.each do |referer|
        next if referer.blank?
        
        begin
          uri = URI.parse(referer.gsub(' ', '%20'))
          next unless uri.query
          
          params = CGI.parse(uri.query)
          query = params['q']&.first || params['query']&.first || params['search']&.first
          
          if query.present? && query.length > 2 && !query.match?(/\A[a-f0-9-]+\z/) # Skip UUIDs/hashes
            term = query.downcase.strip.gsub(/[^\w\s]/, '').strip
            search_terms[term] = (search_terms[term] || 0) + 1 if term.present?
          end
        rescue URI::InvalidURIError, StandardError => e
          # Skip invalid URIs
          Rails.logger.debug "Skipping invalid referrer: #{referer} - #{e.message}"
        end
      end

      # Check for search within site (internal searches)
      internal_search_visits = Visit.where("referer ILIKE '%/search%' OR referer ILIKE '%q=%greyhat%'")
                                   .count
      
      if internal_search_visits > 0
        search_terms['búsqueda interna del sitio'] = internal_search_visits
      end

      # Add some common search scenarios based on referrer patterns
      tech_searches = Visit.where("referer ILIKE '%google%' AND (
                                   referer ILIKE '%tecnolog%' OR 
                                   referer ILIKE '%programming%' OR
                                   referer ILIKE '%desarrollo%' OR
                                   referer ILIKE '%software%')")
                           .count
      
      if tech_searches > 0
        search_terms['términos relacionados con tecnología'] = tech_searches
      end

      # If still no data, add some sample data indicating the system is working
      if search_terms.empty?
        # Check if we have any Google referrers at all
        has_google_referrers = Visit.where("referer ILIKE '%google%'").exists?
        
        if has_google_referrers
          search_terms['términos de búsqueda no detectables'] = Visit.where("referer ILIKE '%google%'").count
        else
          search_terms['no hay datos de búsquedas disponibles'] = 0
        end
      end

    rescue StandardError => e
      Rails.logger.error "Error extracting search terms: #{e.message}"
      search_terms['error en análisis de búsquedas'] = 0
    end

    # Return top 10 search terms
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
    # More meaningful exit pages calculation - show actual content
    exit_pages = {}

    begin
      # Get top exit pages by showing actual page/post titles with visit counts
      post_exits = Visit.joins('JOIN posts ON visits.visitable_id = posts.id')
                       .where("visits.visitable_type = 'Post'")
                       .where('visits.viewed_at >= ?', 1.week.ago)
                       .group('posts.title')
                       .order('COUNT(visits.id) DESC')
                       .limit(5)
                       .count
      
      page_exits = Visit.joins('JOIN pages ON visits.visitable_id = pages.id')
                       .where("visits.visitable_type = 'Page'")
                       .where('visits.viewed_at >= ?', 1.week.ago)
                       .group('pages.name')
                       .order('COUNT(visits.id) DESC')
                       .limit(3)
                       .count
      
      # Combine and format results
      post_exits.each do |title, count|
        exit_pages["📄 #{title.truncate(40)}"] = count
      end
      
      page_exits.each do |name, count|
        page_name = case name
                   when 'index' then 'Página de Inicio'
                   when 'about' then 'Acerca de'
                   when 'contact' then 'Contacto'
                   when 'newsletter' then 'Newsletter'
                   else name.humanize
                   end
        exit_pages["🏠 #{page_name}"] = count
      end
      
      # If no data, provide a fallback
      if exit_pages.empty?
        exit_pages['Sin datos de páginas de salida'] = 0
      end
      
    rescue => e
      Rails.logger.error "Error calculating exit pages: #{e.message}"
      exit_pages = { 'Error calculando páginas de salida' => 0 }
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

    begin
      # Content volume insights - always available
      total_published = Post.published.count
      if total_published >= 50
        insights << "🎉 ¡Tienes más de #{total_published} artículos publicados!"
      elsif total_published >= 20
        insights << "📚 #{total_published} artículos publicados - ¡sigue así!"
      elsif total_published >= 10
        insights << "📖 #{total_published} artículos - vas por buen camino"
      elsif total_published > 0
        insights << "🌱 #{total_published} artículos - ¡sigue creando contenido!"
      end

      # Recent content performance
      recent_posts_count = Post.where('created_at >= ?', 30.days.ago).count
      if recent_posts_count > 0
        insights << "📝 Has publicado #{recent_posts_count} artículos este mes"
      end

      # Recent engagement insights
      recent_comments = Comment.where('created_at >= ?', 7.days.ago).count
      if recent_comments > 0
        insights << "💬 #{recent_comments} comentarios esta semana"
      end

      # Newsletter clicks insights
      newsletter_clicks = Visit.where(action_type: 'newsletter_click')
                              .where('viewed_at >= ?', 30.days.ago)
                              .count
      if newsletter_clicks > 0
        insights << "📧 #{newsletter_clicks} clics al newsletter este mes"
      end

      # Visit insights
      total_visits = Visit.where('viewed_at >= ?', 30.days.ago).count
      if total_visits > 1000
        insights << "🚀 ¡Más de #{total_visits} visitas este mes!"
      elsif total_visits > 100
        insights << "📊 #{total_visits} visitas este mes"
      end

      # Best performing content type by tags (simplified)
      if Post.published.joins(:tags).exists?
        begin
          # Simple approach - get most used tag
          top_tag_name = Tag.joins(:posts)
                           .where(posts: { draft: false })
                           .group('tags.name')
                           .order('COUNT(posts.id) DESC')
                           .limit(1)
                           .pluck('tags.name')
                           .first
          
          if top_tag_name
            insights << "🏆 Tu tema más frecuente: '#{top_tag_name}'"
          end
        rescue => e
          Rails.logger.debug "Error getting top tag: #{e.message}"
        end
      end

      # Fallback insights if no specific data
      if insights.empty?
        if total_published == 0
          insights << "🌟 ¡Bienvenido! Crea tu primer artículo para comenzar"
        else
          insights << "📈 Crea más contenido para generar insights detallados"
          insights << "🔍 Los insights mejorarán con más datos de visitas"
        end
      end

    rescue => e
      Rails.logger.error "Error generating content insights: #{e.message}"
      insights = ["⚠️ Error generando insights"]
    end

    insights
  end

  def analyze_tag_performance
    return {} unless Post.published.any?

    begin
      # Simplified approach - tag performance based on post count and basic metrics
      tag_performance = Tag.joins(:posts)
                           .where(posts: { draft: false })
                           .group('tags.name')
                           .order('COUNT(posts.id) DESC')
                           .limit(10)
                           .count

      # If we have visits data, try to get visit-based performance
      if Visit.where(visitable_type: 'Post').exists?
        visit_based = Tag.joins(:posts)
                         .joins("JOIN visits ON visits.visitable_id = posts.id AND visits.visitable_type = 'Post'")
                         .group('tags.name')
                         .order('COUNT(visits.id) DESC')
                         .limit(10)
                         .count
        
        # Use visit-based if it has data, otherwise fall back to post count
        tag_performance = visit_based.any? ? visit_based : tag_performance
      end
      
      tag_performance
    rescue => e
      Rails.logger.debug "Error analyzing tag performance: #{e.message}"
      # Fallback to simple tag count
      Tag.joins(:posts)
         .where(posts: { draft: false })
         .group('tags.name')
         .order('COUNT(posts.id) DESC')
         .limit(5)
         .count
    end
  end
end
