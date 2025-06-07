# frozen_string_literal: true

class TagsController < ApplicationController
  def index
    @tags = Tag.joins(:posts)
               .where(posts: { draft: false })
               .group('tags.id, tags.name')
               .order('COUNT(posts.id) DESC, tags.name ASC')
               .limit(20)
               .pluck(:name)
    
    render json: @tags
  end
end