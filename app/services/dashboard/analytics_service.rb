# frozen_string_literal: true

class Dashboard::AnalyticsService
  def initialize(user, params = {})
    @user = user
    @params = params
  end

  def generate_insights
    {
      performance_insights: generate_performance_insights,
      content_insights: generate_content_insights,
      tag_performance: analyze_tag_performance,
      popular_search_terms: extract_popular_search_terms,
      user_agents_summary: analyze_user_agents,
      bounce_rate: calculate_bounce_rate,
      avg_session_duration: calculate_avg_session_duration,
      top_exit_pages: find_top_exit_pages,
      conversion_funnel: analyze_conversion_funnel
    }
  end

  private

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
      'Conversión a Artículos' => total_visitors.positive? ? "#{( (post_visitors.to_f / total_visitors) * 100).round(1)}%" : '0%',
      'Conversión a Contacto' => total_visitors.positive? ? "#{( (contact_visitors.to_f / total_visitors) * 100).round(1)}%" : '0%'
    }
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
    # Use optimized queries with the GIN index for better performance
    browsers = {}
    devices = {}
    os_systems = {}
    
    # Browser analysis
    browsers['Chrome'] = Visit.where("user_agent ILIKE '%chrome%' AND user_agent NOT ILIKE '%edge%'").count
    browsers['Firefox'] = Visit.where("user_agent ILIKE '%firefox%'").count
    browsers['Safari'] = Visit.where("user_agent ILIKE '%safari%' AND user_agent NOT ILIKE '%chrome%'").count
    browsers['Edge'] = Visit.where("user_agent ILIKE '%edge%'").count
    
    total_with_agents = Visit.where.not(user_agent: [nil, '']).count
    browsers['Other'] = [total_with_agents - browsers.values.sum, 0].max
    
    # Device analysis
    devices['Mobile'] = Visit.where("user_agent ILIKE ANY (ARRAY['%mobile%', '%android%', '%iphone%'])").count
    devices['Tablet'] = Visit.where("user_agent ILIKE ANY (ARRAY['%tablet%', '%ipad%'])").count
    devices['Desktop'] = [total_with_agents - devices.values.sum, 0].max
    
    # OS analysis
    os_systems['Windows'] = Visit.where("user_agent ILIKE '%windows%'").count
    os_systems['macOS'] = Visit.where("user_agent ILIKE ANY (ARRAY['%mac os%', '%macintosh%'])").count
    os_systems['Linux'] = Visit.where("user_agent ILIKE '%linux%'").count
    os_systems['Android'] = Visit.where("user_agent ILIKE ANY (ARRAY['%android%'])").count
    os_systems['iOS'] = Visit.where("user_agent ILIKE ANY (ARRAY['%ios%', '%iphone%', '%ipad%'])").count
    os_systems['Other'] = [total_with_agents - os_systems.values.sum, 0].max

    {
      browsers: browsers.select { |_, count| count > 0 }.sort_by { |_, count| -count }.first(5).to_h,
      devices: devices.select { |_, count| count > 0 }.sort_by { |_, count| -count }.to_h,
      operating_systems: os_systems.select { |_, count| count > 0 }.sort_by { |_, count| -count }.first(5).to_h
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
    social_media_visits = Visit.social_media.count
    search_engine_visits = Visit.search_engine.count
    direct_visits = Visit.where(referer: [nil, '']).count

    if social_media_visits > search_engine_visits && social_media_visits > direct_visits
      social_percentage = ((social_media_visits.to_f / Visit.count) * 100).round
      insights << "Las redes sociales generan el #{social_percentage}% de tu tráfico"
    elsif search_engine_visits > direct_visits
      search_percentage = ((search_engine_visits.to_f / Visit.count) * 100).round
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