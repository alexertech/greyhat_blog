# frozen_string_literal: true

# PagesController - Related to static content
class PagesController < ApplicationController
  after_action :track_visit

  def index
    @page = Page.find(1)
  end

  def about
    @page = Page.find(2)
  end

  def services
    @page = Page.find(3)
  end

  def newsletter
    @page = Page.find(5)
    @sample_post = Post.published.order(created_at: :desc).limit(5).sample
  end

  def track_newsletter_click
    # Track newsletter subscription click
    @page = Page.find(5)
    
    @page.visits.create(
      ip_address: request.remote_ip,
      user_agent: request.user_agent,
      referer: request.referer,
      action_type: 'newsletter_click'
    )

    # Record health check if response time tracking is enabled
    start_time = Time.current
    response_time = (Time.current - start_time) * 1000
    SiteHealth.record_response_time(response_time)

    render json: { status: 'success' }
  rescue StandardError => e
    SiteHealth.record_error('newsletter_click_error', { message: e.message })
    render json: { status: 'error' }, status: 500
  end

  def contact
    @page = Page.find(4)
  end

  # Tailwind preview methods
  def tailwind_index
    @page = Page.find(1)
    render 'index_tailwind'
  end

  def tailwind_about
    @page = Page.find(2)
    render 'about_tailwind'
  end

  def tailwind_newsletter
    @page = Page.find(5)
    @sample_post = Post.published.order(created_at: :desc).limit(5).sample
    render 'newsletter_tailwind'
  end

  def tailwind_services
    @page = Page.find(3)
    render 'services_tailwind'
  end

  private

  def track_visit
    # Only increment unique visits if this IP hasn't visited in the last 24 hours
    unless @page.visits.where(ip_address: request.remote_ip)
                .where('viewed_at >= ?', 24.hours.ago).exists?
      @page.increment!(:unique_visits)
    end

    # Record detailed visit data
    @page.visits.create(
      ip_address: request.remote_ip,
      user_agent: request.user_agent,
      referer: request.referer
    )
  end
end
