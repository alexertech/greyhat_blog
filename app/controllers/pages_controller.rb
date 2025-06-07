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
