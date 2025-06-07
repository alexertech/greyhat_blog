# frozen_string_literal: true

class SearchController < ApplicationController
  def index
    @query = params[:q].to_s.strip
    @posts = []
    
    if @query.present?
      @posts = Post.published
                   .joins(:rich_text_body)
                   .where(
                     'posts.title ILIKE :query OR action_text_rich_texts.body ILIKE :query',
                     query: "%#{@query}%"
                   )
                   .includes(:image_attachment)
                   .order(created_at: :desc)
                   .limit(20)
    end
  end
end
