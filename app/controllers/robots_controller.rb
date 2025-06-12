# frozen_string_literal: true

class RobotsController < ApplicationController
  def index
    respond_to do |format|
      format.text { render plain: robots_txt_content }
    end
  end
  
  private
  
  def robots_txt_content
    if Rails.env.production?
      <<~ROBOTS
        User-agent: *
        Allow: /
        
        # Disallow admin and dashboard areas
        Disallow: /dashboards
        Disallow: /users/sign_in
        Disallow: /users/sign_up
        Disallow: /users/password
        
        # Disallow search result pages with parameters
        Disallow: /search?*
        
        # Allow specific crawlers access to everything
        User-agent: Googlebot
        Allow: /
        
        User-agent: Bingbot
        Allow: /
        
        # Sitemap location
        Sitemap: #{sitemap_url}
        
        # Crawl delay for general bots
        Crawl-delay: 1
      ROBOTS
    else
      # Block all crawlers in non-production environments
      <<~ROBOTS
        User-agent: *
        Disallow: /
      ROBOTS
    end
  end
end