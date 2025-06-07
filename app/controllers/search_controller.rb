# frozen_string_literal: true

class SearchController < ApplicationController
  def index
    @query = params[:q].to_s.strip
    @tag = params[:tag].to_s.strip
    @posts = []
    
    if @tag.present?
      # Tag-based search
      @posts = Post.published
                   .joins(:tags)
                   .where(tags: { name: @tag })
                   .includes(:image_attachment, :tags)
                   .order(created_at: :desc)
                   .limit(20)
    elsif @query.present?
      # Text search including tags
      @posts = Post.published
                   .left_joins(:rich_text_body, :tags)
                   .where(
                     'posts.title ILIKE :query OR action_text_rich_texts.body ILIKE :query OR tags.name ILIKE :query',
                     query: "%#{@query}%"
                   )
                   .includes(:image_attachment, :tags)
                   .distinct
                   .order(created_at: :desc)
                   .limit(20)
    end
  end
end
