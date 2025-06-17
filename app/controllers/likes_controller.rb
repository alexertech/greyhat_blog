# frozen_string_literal: true

class LikesController < ApplicationController
  before_action :find_post
  before_action :verify_authenticity_token
  before_action :check_rate_limit
  before_action :detect_bots

  def toggle
    ip_address = get_client_ip
    
    # Check for suspicious rapid-fire requests
    if rapid_like_attempt?(ip_address)
      Rails.logger.warn "Rapid like attempt detected from IP: #{ip_address} for post: #{@post.id}"
      render json: { error: 'Too many requests' }, status: :too_many_requests
      return
    end

    begin
      if @post.liked_by?(ip_address)
        @post.unlike_by!(ip_address)
        liked = false
        action = 'unliked'
      else
        @post.like_by!(ip_address)
        liked = true
        action = 'liked'
      end

      # Log the action for monitoring
      Rails.logger.info "Post #{@post.id} #{action} by IP: #{ip_address}"

      render json: {
        liked: liked,
        likes_count: @post.reload.likes_count
      }
    rescue StandardError => e
      Rails.logger.error "Error processing like for post #{@post.id}: #{e.message}"
      render json: { error: 'Internal error' }, status: :internal_server_error
    end
  end

  private

  def find_post
    @post = Post.published.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Post not found' }, status: :not_found
  end

  def check_rate_limit
    ip_address = get_client_ip
    cache_key = "like_rate_limit:#{ip_address}"
    
    # Allow 10 likes per minute per IP
    current_count = Rails.cache.read(cache_key) || 0
    
    if current_count >= 10
      render json: { error: 'Rate limit exceeded' }, status: :too_many_requests
      return
    end
    
    Rails.cache.write(cache_key, current_count + 1, expires_in: 1.minute)
  end

  def detect_bots
    user_agent = request.user_agent.to_s.downcase
    
    # Use same bot detection logic as Visit model
    if user_agent.match?(/(bot|crawler|spider|yahoo|slurp|daum|yandex|googlebot|bingbot|baiduspider|twitterbot|facebookexternalhit|rogerbot|linkedinbot|embedly|quora|pinterest|slackbot|redditbot|snapchat|applebot)/i)
      Rails.logger.warn "Bot detected attempting to like post #{params[:id]}: #{user_agent}"
      render json: { error: 'Automated requests not allowed' }, status: :forbidden
      return
    end
  end

  def rapid_like_attempt?(ip_address)
    cache_key = "rapid_like:#{ip_address}:#{@post.id}"
    last_attempt = Rails.cache.read(cache_key)
    
    if last_attempt && Time.current - last_attempt < 2.seconds
      return true
    end
    
    Rails.cache.write(cache_key, Time.current, expires_in: 5.seconds)
    false
  end

  def get_client_ip
    # More robust IP detection that considers proxies
    request.env['HTTP_X_FORWARDED_FOR']&.split(',')&.first&.strip ||
      request.env['HTTP_X_REAL_IP'] ||
      request.remote_ip
  end
end