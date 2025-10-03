# frozen_string_literal: true

class DashboardsController < ApplicationController
  before_action :authenticate_user!

  def index
    # Build all dashboard data using service
    builder = DashboardBuilderService.new(current_user)
    data = builder.build

    # Assign instance variables for view compatibility
    data.each do |key, value|
      instance_variable_set("@#{key}", value)
    end
  end

  def stats
    @period = params[:period].present? ? params[:period].to_i : 7

    # Build dashboard data with custom period
    builder = DashboardBuilderService.new(current_user, period: @period)
    data = builder.build

    # Assign instance variables for view compatibility
    data.each do |key, value|
      instance_variable_set("@#{key}", value)
    end

    # Stats-specific data
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

    @top_referrers = Dashboard::ReferrerAnalyzer.analyze(@referrer_counts)

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
