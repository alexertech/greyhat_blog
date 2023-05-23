class PostsController < ApplicationController
  before_action :authenticate_user!, except: %i[show list]
  before_action :set_post, only: %i[show edit update destroy]

  # GET /posts
  # GET /posts.json
  def index
    @posts = Post.all
  end

  # Get /blog
  def list
    @posts = Post.order("id DESC").all
  end

  # GET /posts/1
  # GET /posts/1.json
  def show
    track_visit(@post) unless visit_tracked?
  end

  # GET /posts/new
  def new
    @post = Post.new
  end

  # GET /posts/1/edit
  def edit
  end

  # POST /posts
  # POST /posts.json
  def create
    @post = Post.new(post_params)

    respond_to do |format|
      if @post.save
        format.html do
          redirect_to @post, notice: "Post was successfully created."
        end
        format.json { render :show, status: :created, location: @post }
      else
        format.html { render :new }
        format.json { render json: @post.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /posts/1
  # PATCH/PUT /posts/1.json
  def update
    respond_to do |format|
      if @post.update(post_params)
        format.html do
          redirect_to @post, notice: "Post was successfully updated."
        end
        format.json { render :show, status: :ok, location: @post }
      else
        format.html { render :edit }
        format.json { render json: @post.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /posts/1
  # DELETE /posts/1.json
  def destroy
    @post.destroy
    respond_to do |format|
      format.html do
        redirect_to posts_url, notice: "Post was successfully destroyed."
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

  def track_visit(blog_post)
    blog_post.increment!(:unique_visits)
    session[:visited_blog_posts] ||= []
    session[:visited_blog_posts] << blog_post.id
  end

  def visit_tracked?
    session[:visited_blog_posts]&.include?(params[:id].to_i)
  end
  
end
