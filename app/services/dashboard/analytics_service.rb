# frozen_string_literal: true

class Dashboard::AnalyticsService
  def initialize(user, params = {})
    @user = user
    @params = params
    @traffic_service = TrafficAnalyticsService.new(params)
    @content_service = ContentAnalyticsService.new(params)
    @conversion_service = ConversionAnalyticsService.new(params)
  end

  def generate_insights
    {
      performance_insights: @content_service.performance_insights,
      content_insights: @content_service.content_insights,
      tag_performance: @content_service.tag_performance,
      popular_search_terms: @traffic_service.popular_search_terms,
      user_agents_summary: @traffic_service.user_agents_summary,
      bounce_rate: @traffic_service.bounce_rate,
      avg_session_duration: @traffic_service.avg_session_duration,
      top_exit_pages: @traffic_service.top_exit_pages,
      conversion_funnel: @conversion_service.conversion_funnel
    }
  end

end