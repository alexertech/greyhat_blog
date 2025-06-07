# frozen_string_literal: true

class DashboardsController < ApplicationController
  before_action :authenticate_user!

  def index
    @total_visits = Visit.count
    @visits_today = Visit.where('viewed_at >= ?', Time.zone.now.beginning_of_day).count
    @visits_this_week = Visit.where('viewed_at >= ?', 1.week.ago).count
    @most_visited_posts = Post.most_visited(5)
    
    # Visit counts by page - optimized to avoid N+1 queries
    pages_with_visits = Page.includes(:visits).where(id: [1, 2, 3]).index_by(&:id)
    @home_visits = pages_with_visits[1]&.visits&.size || 0
    @about_visits = pages_with_visits[2]&.visits&.size || 0
    @services_visits = pages_with_visits[3]&.visits&.size || 0
    @posts_visits = Visit.where(visitable_type: 'Post').count
    
    # Comment count for dashboard
    @comment_count = Comment.count
    @pending_comment_count = Comment.pending.count
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
end
