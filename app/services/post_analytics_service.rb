# frozen_string_literal: true

class PostAnalyticsService
  def initialize(post)
    @post = post
  end

  def engagement_score
    # Use cached values when available to avoid repeated database queries
    visit_count = @post.unique_visits || 0
    return 0 if visit_count.zero?

    # Weighted score: views (40%) + comments (40%) + recent activity (20%)
    view_score = [visit_count / 100.0, 10].min * 4
    comment_score = [approved_comments_count * 2, 10].min * 4
    recent_score = [recent_visits_count(7) / 10.0, 10].min * 2

    (view_score + comment_score + recent_score).round(1)
  end

  def newsletter_conversions
    # Optimized query using proper indexing - will be fast once indexes are applied
    Visit.where(visitable_type: 'Page', visitable_id: 5, action_type: 'newsletter_click')
         .joins("JOIN visits referer_visits ON referer_visits.ip_address = visits.ip_address")
         .where("referer_visits.visitable_type = 'Post' AND referer_visits.visitable_id = ?", @post.id)
         .where("visits.viewed_at - referer_visits.viewed_at BETWEEN INTERVAL '0 minutes' AND INTERVAL '1 hour'")
         .where("referer_visits.viewed_at < visits.viewed_at")
         .count
  end

  def performance_trend(days = 3)
    # Compare last 3 days vs previous 3 days for more relevant trends
    current_period = visits_in_period(days.days.ago, Time.current)
    previous_period = visits_in_period((days * 2).days.ago, days.days.ago)

    # If no previous data, show trend based on post age
    if previous_period.zero?
      return current_period > 0 ? 100 : 0
    end

    # Cap extreme values for better UX
    trend = ((current_period - previous_period) / previous_period.to_f * 100).round(1)
    [[-95, trend].max, 500].min  # Cap between -95% and +500%
  end

  def related_posts(limit = 3)
    return Post.published.where.not(id: @post.id).limit(limit) if @post.tags.empty?

    # Use a subquery approach to avoid GROUP BY issues with includes
    related_post_ids = Post.published
                           .joins(:tags)
                           .where(tags: { id: @post.tag_ids })
                           .where.not(id: @post.id)
                           .group('posts.id')
                           .order('COUNT(tags.id) DESC, posts.created_at DESC')
                           .limit(limit)
                           .pluck(:id)

    return Post.published.where.not(id: @post.id).limit(limit) if related_post_ids.empty?

    Post.where(id: related_post_ids)
        .order(Arel.sql("array_position(ARRAY[#{related_post_ids.join(',')}], posts.id)"))
  end

  private

  def approved_comments_count
    @approved_comments_count ||= @post.comments.approved.count
  end

  def recent_visits_count(days)
    @recent_visits_count ||= {}
    @recent_visits_count[days] ||= @post.visits.where('viewed_at >= ?', days.days.ago).count
  end

  def visits_in_period(start_time, end_time)
    @post.visits.where(viewed_at: start_time..end_time).count
  end
end