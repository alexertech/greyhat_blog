# frozen_string_literal: true

class ContentAnalyticsService
  def initialize(params = {})
    @params = params
  end

  def content_insights
    insights = []

    begin
      # Content volume insights - always available
      total_published = Post.published.count
      insights << content_volume_insight(total_published)

      # Recent content performance
      recent_posts_count = Post.where('created_at >= ?', 30.days.ago).count
      insights << "📝 Has publicado #{recent_posts_count} artículos este mes" if recent_posts_count > 0

      # Recent engagement insights
      recent_comments = Comment.where('created_at >= ?', 7.days.ago).count
      insights << "💬 #{recent_comments} comentarios esta semana" if recent_comments > 0

      # Newsletter clicks insights
      newsletter_clicks = Visit.where(action_type: 'newsletter_click')
                              .where('viewed_at >= ?', 30.days.ago)
                              .count
      insights << "📧 #{newsletter_clicks} clics al newsletter este mes" if newsletter_clicks > 0

      # Visit insights
      total_visits = Visit.where('viewed_at >= ?', 30.days.ago).count
      insights << visit_volume_insight(total_visits)

      # Best performing content type by tags
      if Post.published.joins(:tags).exists?
        top_tag_name = Tag.joins(:posts)
                         .where(posts: { draft: false })
                         .group('tags.name')
                         .order('COUNT(posts.id) DESC')
                         .limit(1)
                         .pluck('tags.name')
                         .first
        insights << "🏆 Tu tema más frecuente: '#{top_tag_name}'" if top_tag_name
      end

      # Fallback insights if no specific data
      if insights.empty?
        insights << fallback_insight(total_published)
      end

    rescue => e
      Rails.logger.error "Error generating content insights: #{e.message}"
      insights = ["⚠️ Error generando insights"]
    end

    insights
  end

  def tag_performance
    return {} unless Post.published.any?

    begin
      # Tag performance based on post count and visits if available
      tag_performance = Tag.joins(:posts)
                           .where(posts: { draft: false })
                           .group('tags.name')
                           .order('COUNT(posts.id) DESC')
                           .limit(10)
                           .count

      # Try to get visit-based performance if visits exist
      if Visit.where(visitable_type: 'Post').exists?
        visit_based = Tag.joins(:posts)
                         .joins("JOIN visits ON visits.visitable_id = posts.id AND visits.visitable_type = 'Post'")
                         .group('tags.name')
                         .order('COUNT(visits.id) DESC')
                         .limit(10)
                         .count

        # Use visit-based if it has data, otherwise fall back
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

  def performance_insights
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

  private

  def content_volume_insight(total_published)
    case total_published
    when 50.. then "🎉 ¡Tienes más de #{total_published} artículos publicados!"
    when 20..49 then "📚 #{total_published} artículos publicados - ¡sigue así!"
    when 10..19 then "📖 #{total_published} artículos - vas por buen camino"
    when 1..9 then "🌱 #{total_published} artículos - ¡sigue creando contenido!"
    else "🌟 ¡Bienvenido! Crea tu primer artículo para comenzar"
    end
  end

  def visit_volume_insight(total_visits)
    case total_visits
    when 1000.. then "🚀 ¡Más de #{total_visits} visitas este mes!"
    when 100..999 then "📊 #{total_visits} visitas este mes"
    else nil
    end
  end

  def fallback_insight(total_published)
    if total_published == 0
      "🌟 ¡Bienvenido! Crea tu primer artículo para comenzar"
    else
      "📈 Crea más contenido para generar insights detallados"
    end
  end
end