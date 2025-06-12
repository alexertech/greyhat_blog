# frozen_string_literal: true

class SitemapsController < ApplicationController
  before_action :set_format_xml
  
  def index
    @posts = Post.published.includes(:tags).order(updated_at: :desc)
    @tags = Tag.joins(:posts).where(posts: { draft: false }).distinct
    
    respond_to do |format|
      format.xml { render layout: false }
    end
  end
  
  private
  
  def set_format_xml
    request.format = :xml
  end
end