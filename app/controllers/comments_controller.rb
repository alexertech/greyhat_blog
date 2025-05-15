# frozen_string_literal: true

class CommentsController < ApplicationController
  before_action :set_post
  
  def create
    @comment = @post.comments.new(comment_params)
    
    respond_to do |format|
      if @comment.save
        format.html { redirect_to post_path(@post), notice: 'Thank you for your comment!' }
        format.turbo_stream
      else
        format.html { redirect_to post_path(@post), alert: @comment.errors.full_messages.to_sentence }
        format.turbo_stream { render turbo_stream: turbo_stream.replace('comment_form', 
          partial: 'comments/form', locals: { post: @post, comment: @comment }) }
      end
    end
  end
  
  private
  
  def set_post
    @post = Post.find_by!(slug: params[:post_id])
  end
  
  def comment_params
    params.require(:comment).permit(:username, :email, :body, :website)
  end
end 