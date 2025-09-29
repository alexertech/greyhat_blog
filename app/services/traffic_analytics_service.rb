# frozen_string_literal: true

class TrafficAnalyticsService
  def initialize(params = {})
    @params = params
  end

  def bounce_rate
    total_visits = Visit.count
    return 0 if total_visits.zero?

    recent_visits = Visit.where('viewed_at >= ?', 1.month.ago).count
    return 0 if recent_visits.zero?

    # Estimate bounce rate based on single-page visits from same IP
    bounces = Visit.where('viewed_at >= ?', 1.month.ago)
                   .group(:ip_address)
                   .having('COUNT(*) = 1')
                   .count
                   .size

    ((bounces.to_f / recent_visits) * 100).round(1)
  end

  def avg_session_duration
    total_visits = Visit.where('viewed_at >= ?', 1.week.ago).count
    return 0 if total_visits.zero?

    unique_visitors = Visit.where('viewed_at >= ?', 1.week.ago)
                           .distinct
                           .count(:ip_address)
    return 0 if unique_visitors.zero?

    avg_pages_per_visitor = total_visits.to_f / unique_visitors
    (avg_pages_per_visitor * 90).round # seconds, ~1.5 min per page
  end

  def top_exit_pages
    exit_pages = {}

    begin
      # Get top exit pages by showing actual content titles
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

      # Format results with emojis for visual distinction
      post_exits.each { |title, count| exit_pages["📄 #{title.truncate(40)}"] = count }
      page_exits.each do |name, count|
        page_name = format_page_name(name)
        exit_pages["🏠 #{page_name}"] = count
      end

      exit_pages['Sin datos de páginas de salida'] = 0 if exit_pages.empty?

    rescue => e
      Rails.logger.error "Error calculating exit pages: #{e.message}"
      exit_pages = { 'Error calculando páginas de salida' => 0 }
    end

    exit_pages
  end

  def user_agents_summary
    browsers, devices, os_systems = {}, {}, {}

    # Browser analysis using optimized queries
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
    os_systems['Android'] = Visit.where("user_agent ILIKE '%android%'").count
    os_systems['iOS'] = Visit.where("user_agent ILIKE ANY (ARRAY['%ios%', '%iphone%', '%ipad%'])").count
    os_systems['Other'] = [total_with_agents - os_systems.values.sum, 0].max

    {
      browsers: browsers.select { |_, count| count > 0 }.sort_by { |_, count| -count }.first(5).to_h,
      devices: devices.select { |_, count| count > 0 }.sort_by { |_, count| -count }.to_h,
      operating_systems: os_systems.select { |_, count| count > 0 }.sort_by { |_, count| -count }.first(5).to_h
    }
  end

  def popular_search_terms
    search_terms = {}

    begin
      # Extract search terms from Google referrers
      google_referrers = Visit.where("referer ILIKE '%google%' AND (referer ILIKE '%q=%' OR referer ILIKE '%query=%')")
                              .pluck(:referer)

      google_referrers.each do |referer|
        next if referer.blank?

        begin
          uri = URI.parse(referer.gsub(' ', '%20'))
          next unless uri.query

          params = CGI.parse(uri.query)
          query = params['q']&.first || params['query']&.first || params['search']&.first

          if query.present? && query.length > 2 && !query.match?(/\A[a-f0-9-]+\z/)
            term = query.downcase.strip.gsub(/[^\w\s]/, '').strip
            search_terms[term] = (search_terms[term] || 0) + 1 if term.present?
          end
        rescue URI::InvalidURIError, StandardError => e
          Rails.logger.debug "Skipping invalid referrer: #{referer} - #{e.message}"
        end
      end

      # Add fallback data if no search terms found
      if search_terms.empty?
        has_google_referrers = Visit.where("referer ILIKE '%google%'").exists?
        search_terms[has_google_referrers ? 'términos de búsqueda no detectables' : 'no hay datos de búsquedas disponibles'] =
          has_google_referrers ? Visit.where("referer ILIKE '%google%'").count : 0
      end

    rescue StandardError => e
      Rails.logger.error "Error extracting search terms: #{e.message}"
      search_terms['error en análisis de búsquedas'] = 0
    end

    search_terms.sort_by { |_, count| -count }.first(10).to_h
  end

  private

  def format_page_name(name)
    case name
    when 'index' then 'Página de Inicio'
    when 'about' then 'Acerca de'
    when 'contact' then 'Contacto'
    when 'newsletter' then 'Newsletter'
    else name.humanize
    end
  end
end