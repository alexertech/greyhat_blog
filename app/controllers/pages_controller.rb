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

  def contact
    @page = Page.find(4)
  end

  private

  def track_visit
    # Keep the legacy counter for backward compatibility
    @page.increment!(:unique_visits)
    
    # Record detailed visit data
    @page.visits.create(
      ip_address: request.remote_ip,
      user_agent: request.user_agent,
      referer: request.referer
    )
  end
end
