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
    @posts = Post.published.includes(:image_attachment, :rich_text_body, :tags).order(created_at: :desc).paginate(
      page: params[:page], per_page: 20
    )
    
    # Calculate total visits across all published posts for counter
    @total_published_visits = Visit.joins("JOIN posts ON visits.visitable_id = posts.id")
                                   .where("visits.visitable_type = 'Post' AND posts.draft = false")
                                   .count
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
