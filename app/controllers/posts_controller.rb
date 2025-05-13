# frozen_string_literal: true

# PostsController - Related to blog posts
class PostsController < ApplicationController
  before_action :authenticate_user!, except: %i[show list]
  before_action :set_post, only: %i[show edit update destroy]
  before_action :track_visit, only: %i[show]

  # GET /posts
  def index
    @posts = Post.all
  end

  # Get /blog
  def list
    @posts = Post.order('id DESC').all
  end

  # GET /posts/1
  def show; end

  # GET /posts/new
  def new
    @post = Post.new
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
    @post = Post.find_by_slug(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def post_params
    params.require(:post).permit(:title, :body, :image)
  end

  def track_visit
    # Keep the legacy counter for backward compatibility
    @post.increment!(:unique_visits)
    
    # Record detailed visit data
    @post.visits.create(
      ip_address: request.remote_ip,
      user_agent: request.user_agent,
      referer: request.referer
    )
  end
end
