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
  end

  # GET /posts/1
  def show
    @comment = Comment.new
    @related_posts = @post.related_posts.includes(:image_attachment, :tags)
  end

  # GET /posts/new
  def new
    @post = Post.new(draft: true)
  end

  # GET /posts/1/edit
  def edit; end

  # POST /posts
  def create
    @post = Post.new(post_params)

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
    @post = Post.includes(:image_attachment, :visits, :tags, comments: :post).find_by_slug(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def post_params
    params.require(:post).permit(:title, :body, :image, :draft, :tag_names)
  end

  def track_visit
    # Only increment unique visits if this IP hasn't visited in the last 24 hours
    unless @post.visits.where(ip_address: request.remote_ip)
                .where('viewed_at >= ?', 24.hours.ago).exists?
      @post.increment!(:unique_visits)
    end

    # Record detailed visit data
    @post.visits.create(
      ip_address: request.remote_ip,
      user_agent: request.user_agent,
      referer: request.referer
    )
  end

  def ensure_published_or_admin
    return unless @post.draft? && !user_signed_in?

    redirect_to root_path, alert: 'That post is not available.'
  end
end
