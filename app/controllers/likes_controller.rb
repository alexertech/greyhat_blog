# frozen_string_literal: true

class LikesController < ApplicationController
  before_action :find_post

  def toggle
    ip_address = request.remote_ip
    
    if @post.liked_by?(ip_address)
      @post.unlike_by!(ip_address)
      liked = false
    else
      @post.like_by!(ip_address)
      liked = true
    end

    render json: {
      liked: liked,
      likes_count: @post.reload.likes_count
    }
  end

  private

  def find_post
    @post = Post.find(params[:id])
  end
end