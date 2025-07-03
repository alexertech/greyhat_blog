# frozen_string_literal: true

class DashboardsController < ApplicationController
  before_action :authenticate_user!

  def index
    # Core metrics - optimized with single query
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
    @social_media_visits = Visit.social_media.count
    @search_engine_visits = Visit.search_engine.count
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

    # Analytics insights - get all data from service
    analytics_service = Dashboard::AnalyticsService.new(current_user)
    insights = analytics_service.generate_insights
    @popular_search_terms = insights[:popular_search_terms]
    @user_agents_summary = insights[:user_agents_summary]
    @content_insights = insights[:content_insights]
    @tag_performance = insights[:tag_performance]
    @bounce_rate = insights[:bounce_rate]
    @avg_session_duration = insights[:avg_session_duration]
    @top_exit_pages = insights[:top_exit_pages]
    @conversion_funnel = insights[:conversion_funnel]

    # Top referrers for quick view - exclude self-referrers
    @top_referrers_preview = Dashboard::ReferrerAnalyzer.analyze(
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
    @top_referrers = Dashboard::ReferrerAnalyzer.analyze(@referrer_counts)
    @social_media_visits = Visit.social_media.count
    @search_engine_visits = Visit.search_engine.count
    @direct_visits = Visit.where(referer: [nil, '']).count

    # Performance Analytics
    analytics_service = Dashboard::AnalyticsService.new(current_user, {period: @period})
    insights = analytics_service.generate_insights
    @bounce_rate = insights[:bounce_rate]
    @avg_session_duration = insights[:avg_session_duration]
    @top_exit_pages = insights[:top_exit_pages]
    @conversion_funnel = insights[:conversion_funnel]
    @insights = insights[:performance_insights]
    @content_insights = insights[:content_insights]
    @tag_performance = insights[:tag_performance]
    @popular_search_terms = insights[:popular_search_terms]
    @user_agents_summary = insights[:user_agents_summary]

    # Live Activity (last 24 hours)
    @recent_visits = Visit.includes(:visitable)
                          .where('viewed_at >= ?', 24.hours.ago)
                          .order(viewed_at: :desc)
                          .limit(20)
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

end
