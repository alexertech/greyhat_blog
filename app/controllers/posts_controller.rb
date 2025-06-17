# frozen_string_literal: true

# PostsController - Related to blog posts
class PostsController < ApplicationController
  before_action :authenticate_user!, except: %i[show list]
  before_action :set_post, only: %i[show edit update destroy]
  before_action :track_visit, only: %i[show]
  before_action :ensure_published_or_admin, only: %i[show]

  # GET /posts
  def index
    @posts = Post.includes(:image_attachment).order(created_at: :desc).paginate(page: params[:page], per_page: 10)
  end

  # Get /blog
  def list
    # Base query
    posts_query = Post.published.includes(:image_attachment, :rich_text_body, :tags, :user)
    
    # Handle sorting
    case params[:sort]
    when 'most_read'
      @posts = posts_query.order(visits_count: :desc, created_at: :desc)
    when 'most_liked'
      @posts = posts_query.order(likes_count: :desc, created_at: :desc)
    else # 'recent' or default
      @posts = posts_query.order(created_at: :desc)
    end
    
    @posts = @posts.paginate(page: params[:page], per_page: 20)
    
    # Use cached counter or calculate efficiently
    @total_published_visits = Rails.cache.fetch('total_published_visits', expires_in: 1.hour) do
      Post.published.sum(:visits_count) || 0
    end
    
    # Pre-compute excerpts to avoid N+1 queries in the view
    @excerpts = {}
    @reading_times = {}
    @posts.each do |post|
      plain_text = post.rich_text_body&.to_plain_text || ""
      @excerpts[post.id] = plain_text.truncate(200)
      @reading_times[post.id] = (plain_text.split.size/200.0).ceil
    end
    
    # Store current sorting for UI
    @current_sort = params[:sort] || 'recent'
  end

  # GET /posts/1
  def show
    @comment = Comment.new
    @related_posts = @post.related_posts.includes(:image_attachment, :tags)
  end

  # GET /posts/new
  def new
    @post = Post.new(draft: true, user: current_user)
  end

  # GET /posts/1/edit
  def edit; end

  # POST /posts
  def create
    @post = Post.new(post_params)
    @post.user = current_user unless @post.user_id.present?

    respond_to do |format|
      if @post.save
        format.html do
          redirect_to @post, notice: 'Post was successfully created.'
        end
      else
        format.html { render :new }
      end
    end
  end

  # PATCH/PUT /posts/1
  def update
    respond_to do |format|
      if @post.update(post_params)
        format.html do
          redirect_to @post, notice: 'Post was successfully updated.'
        end
      else
        format.html { render :edit }
      end
    end
  end

  # DELETE /posts/1
  # DELETE /posts/1.json
  def destroy
    @post.destroy
    respond_to do |format|
      format.html do
        redirect_to posts_url, notice: 'Post was successfully destroyed.'
      end
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  # def set_post
  #  @post = Post.find(params[:id])
  # end

  def set_post
    # Optimize includes - only load what's needed for the specific action
    @post = Post.includes(:image_attachment, :tags, :user, comments: [:post]).find_by_slug(params[:id])
    redirect_to root_path, alert: 'Post no encontrado.' unless @post
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def post_params
    params.require(:post).permit(:title, :body, :image, :draft, :tag_names, :user_id)
  end

  def track_visit
    return unless @post # Safety check
    
    # Use single atomic operation to avoid race conditions
    Visit.transaction do
      # Check for existing visit in last 24 hours
      existing_visit = Visit.where(
        visitable: @post,
        ip_address: request.remote_ip,
        viewed_at: 24.hours.ago..Time.current
      ).exists?
      
      # Increment unique visits counter if no recent visit
      @post.increment!(:unique_visits) unless existing_visit
      
      # Always record the visit for analytics
      Visit.create!(
        visitable: @post,
        ip_address: request.remote_ip,
        user_agent: request.user_agent,
        referer: request.referer,
        action_type: 'page_view'
      )
    end
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.warn "Failed to track visit for post #{@post&.id}: #{e.message}"
  end

  def ensure_published_or_admin
    return unless @post && @post.draft? && !user_signed_in?

    redirect_to root_path, alert: 'That post is not available.'
  end
end
