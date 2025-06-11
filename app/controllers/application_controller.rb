# frozen_string_literal: true

class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  after_action :record_health_check

  private

  def record_health_check
    # Only record health checks occasionally to avoid spam
    return unless should_record_health_check?

    begin
      # Record successful response
      SiteHealth.record_uptime_check('up')
      
      # Record response time if available
      if @_response_time
        SiteHealth.record_response_time(@_response_time)
      end
    rescue StandardError => e
      Rails.logger.error "Health check recording failed: #{e.message}"
    end
  end

  def should_record_health_check?
    # Record health check on 5% of requests to avoid database spam
    # Focus on important pages (posts, pages, dashboard)
    return false if request.path.match?(/assets|favicon|robots/)
    return false if response.status >= 400
    
    # Random sampling - 5% of successful requests
    rand(100) < 5
  end
end
