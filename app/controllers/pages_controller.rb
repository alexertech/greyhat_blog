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
    @page.increment!(:unique_visits)
    session[:visited_blog_posts] ||= []
    session[:visited_blog_posts] << @page.id
  end

  def visit_tracked?
    session[:visited_blog_posts]&.include?(@page.id)
  end
end
