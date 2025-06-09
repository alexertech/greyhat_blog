# frozen_string_literal: true

require 'ostruct'

class TagsController < ApplicationController
  before_action :authenticate_user!, only: [:suggest]
  protect_from_forgery with: :exception

  def index
    if request.format.json?
      @tags = Tag.joins(:posts)
                 .where(posts: { draft: false })
                 .group('tags.id, tags.name')
                 .order('COUNT(posts.id) DESC, tags.name ASC')
                 .limit(20)
                 .pluck(:name)

      render json: @tags
    else
      # HTML request - render tags browsing page
      @tags_with_counts = Tag.joins(:posts)
                             .where(posts: { draft: false })
                             .group('tags.id, tags.name')
                             .order('COUNT(posts.id) DESC, tags.name ASC')
                             .limit(50)
                             .map do |tag|
                               OpenStruct.new(
                                 id: tag.id,
                                 name: tag.name,
                                 posts_count: tag.posts.published.count
                               )
                             end

      @total_posts = Post.published.count
    end
  end

  def suggest
    content = params[:content].to_s
    existing_tags = params[:existing_tags].to_s.split(',').map(&:strip).reject(&:blank?)

    suggestions = TagSuggestionService.new(content, existing_tags).suggest_tags(5)

    render json: { suggestions: suggestions }
  end
end
