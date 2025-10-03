# frozen_string_literal: true

# Service to build all dashboard data
# Coordinates multiple analytics services and queries to provide
# a complete dashboard dataset
class DashboardBuilderService
  def initialize(user, params = {})
    @user = user
    @params = params
    @period = params[:period] || 7
  end

  def build
    {
      # Core visit metrics
      **visits_metrics,

      # Content performance & metrics
      **content_performance,
      **content_metrics,

      # Traffic analysis
      **traffic_sources,
      **charts_data,

      # Analytics insights
      **analytics_insights,

      # Monitoring & health
      **site_health_metrics,

      # Newsletter funnel
      **newsletter_metrics,

      # Legacy compatibility
      **legacy_metrics
    }
  end

  private

  # Core visits statistics with optimized grouping
  def visits_metrics
    begin
      today_start = Time.zone.now.beginning_of_day
      week_ago = 1.week.ago
      month_ago = 1.month.ago

      visits_stats = Visit.group(
        "CASE
           WHEN viewed_at >= '#{today_start}' THEN 'today'
           WHEN viewed_at >= '#{week_ago}' THEN 'week'
           WHEN viewed_at >= '#{month_ago}' THEN 'month'
           ELSE 'total'
         END"
      ).count

      {
        total_visits: Visit.count,
        visits_today: visits_stats['today'] || 0,
        visits_this_week: visits_stats['week'] || 0,
        visits_this_month: visits_stats['month'] || 0
      }
    rescue => e
      Rails.logger.error "Dashboard visits metrics error: #{e.message}"
      {
        total_visits: Visit.count,
        visits_today: Visit.where('viewed_at >= ?', Time.zone.now.beginning_of_day).count,
        visits_this_week: Visit.where('viewed_at >= ?', 1.week.ago).count,
        visits_this_month: Visit.where('viewed_at >= ?', 1.month.ago).count
      }
    end
  end

  # Top performing and trending posts
  def content_performance
    begin
      most_visited = Post.includes(:comments, :tags, :visits).most_visited(5)

      # Top performing posts based on visits
      top_performing = Post.published
                          .includes(:comments, :tags, :visits)
                          .left_joins(:visits)
                          .group('posts.id')
                          .order('COUNT(visits.id) DESC')
                          .limit(5)

      # Fallback to recent posts if no visits
      if top_performing.empty? || top_performing.sum { |p| p.visits.count }.zero?
        top_performing = Post.published.includes(:comments, :tags).order(created_at: :desc).limit(5)
      end

      # Trending posts (high recent activity)
      trending = Post.published
                    .joins(:visits)
                    .where('visits.viewed_at >= ?', 7.days.ago)
                    .group('posts.id')
                    .order('COUNT(visits.id) DESC')
                    .limit(3)

      # Eager load associations after grouping
      trending = Post.where(id: trending.pluck(:id)).includes(:comments, :tags, :visits) if trending.any?

      # Fallback for trending
      trending = Post.published.includes(:comments, :tags).order(created_at: :desc).limit(3) if trending.empty?

      {
        most_visited_posts: most_visited,
        top_performing_posts: top_performing,
        trending_posts: trending
      }
    rescue => e
      Rails.logger.error "Error calculating content performance: #{e.message}"
      fallback_posts = Post.published.includes(:comments, :tags).order(created_at: :desc).limit(5)
      {
        most_visited_posts: fallback_posts,
        top_performing_posts: fallback_posts,
        trending_posts: fallback_posts.limit(3)
      }
    end
  end

  # Posts, comments, and contacts counts
  def content_metrics
    # Optimized comment stats with single query
    comment_stats = Comment.group(:approved).count
    comment_time_stats = Comment.group(
      "CASE WHEN created_at >= '#{1.month.ago}' THEN 'month' ELSE 'older' END"
    ).count

    {
      total_posts: Post.count,
      published_posts: Post.published.count,
      draft_posts: Post.drafts.count,
      posts_this_month: Post.where('created_at >= ?', 1.month.ago).count,
      comment_count: Comment.count,
      pending_comment_count: comment_stats[false] || 0,
      approved_comment_count: comment_stats[true] || 0,
      comments_this_month: comment_time_stats['month'] || 0,
      total_contacts: Contact.count,
      contacts_this_month: Contact.where('created_at >= ?', 1.month.ago).count
    }
  end

  # Traffic source breakdown
  def traffic_sources
    social = Visit.social_media.count
    search = Visit.search_engine.count
    direct = Visit.where(referer: [nil, '']).count
    total = Visit.count

    # Calculate referral as remainder
    referral = [total - (social + search + direct), 0].max

    # Top referrers preview
    referrer_counts = Visit.where.not(referer: [nil, ''])
                           .where.not("referer ILIKE '%greyhat.cl%'")
                           .where.not("referer ILIKE '%localhost%'")
                           .group(:referer)
                           .order('count_all DESC')
                           .limit(5)
                           .count

    {
      social_media_visits: social,
      search_engine_visits: search,
      direct_visits: direct,
      referral_visits: referral,
      top_referrers_preview: Dashboard::ReferrerAnalyzer.analyze(referrer_counts)
    }
  end

  # Chart data for visualizations
  def charts_data
    raw_chart_data = Visit.count_by_date(30)
    daily_chart = raw_chart_data.map do |date, count|
      formatted_date = case date
      when String
        Date.parse(date).strftime("%m/%d")
      when Date
        date.strftime("%m/%d")
      else
        date.to_s
      end
      [formatted_date, count]
    end

    {
      daily_visits_chart: daily_chart,
      hourly_visits_chart: Visit.count_by_hour
    }
  end

  # Analytics insights from specialized services
  def analytics_insights
    analytics_service = Dashboard::AnalyticsService.new(@user, @params)
    insights = analytics_service.generate_insights

    {
      popular_search_terms: insights[:popular_search_terms],
      user_agents_summary: insights[:user_agents_summary],
      content_insights: insights[:content_insights],
      tag_performance: insights[:tag_performance],
      bounce_rate: insights[:bounce_rate],
      avg_session_duration: insights[:avg_session_duration],
      top_exit_pages: insights[:top_exit_pages],
      conversion_funnel: insights[:conversion_funnel],
      insights: insights[:performance_insights] # For stats view
    }
  end

  # Newsletter conversion funnel metrics
  def newsletter_metrics
    begin
      {
        funnel_data: Visit.funnel_analysis(7),
        newsletter_conversion_rate: Visit.newsletter_conversion_rate(7)
      }
    rescue => e
      Rails.logger.error "Newsletter metrics error: #{e.message}"
      {
        funnel_data: {
          index_visits: 0, article_visits: 0, newsletter_page_visits: 0,
          newsletter_clicks: 0, index_to_articles: 0, articles_to_newsletter: 0,
          newsletter_conversion: 0
        },
        newsletter_conversion_rate: 0
      }
    end
  end

  # Site health monitoring
  def site_health_metrics
    begin
      {
        site_health: SiteHealth.health_status,
        traffic_anomaly: SiteHealth.traffic_anomaly_detection
      }
    rescue => e
      Rails.logger.error "Site health metrics error: #{e.message}"
      {
        site_health: {
          status: 'unknown', uptime: 0, avg_response_time: 0,
          error_count: 0, last_check: nil
        },
        traffic_anomaly: {
          current_hour_visits: 0, average_hourly: 0,
          is_anomaly: false, threshold: 0
        }
      }
    end
  end

  # Legacy variables for backward compatibility
  def legacy_metrics
    {
      home_visits: Visit.joins('JOIN pages ON visits.visitable_id = pages.id')
                       .where("visits.visitable_type = 'Page' AND pages.name = 'index'")
                       .count,
      posts_visits: Visit.where(visitable_type: 'Post').count
    }
  end
end
