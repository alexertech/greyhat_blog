# frozen_string_literal: true

class CommentsController < ApplicationController
  before_action :authenticate_user!, except: [:create]
  before_action :set_post, only: [:create]
  before_action :set_comment, only: [:destroy]
  
  def create
    @comment = @post.comments.new(comment_params)
    
    respond_to do |format|
      if @comment.save
        format.html { redirect_to post_path(@post), notice: '¡Gracias por tu comentario!' }
        format.turbo_stream { render turbo_stream: turbo_stream.prepend("comments", partial: "comments/comment", locals: { comment: @comment }) }
      else
        format.html { redirect_to post_path(@post), alert: @comment.errors.full_messages.to_sentence }
        format.turbo_stream { render turbo_stream: turbo_stream.replace('comment_form', 
          partial: 'comments/form', locals: { post: @post, comment: @comment }) }
      end
    end
  end
  
  def destroy
    post = @comment.post
    @comment.destroy
    
    respond_to do |format|
      format.html { redirect_to dashboards_comments_path, notice: 'Comentario eliminado correctamente.' }
      format.json { head :no_content }
    end
  end
  
  private
  
  def set_post
    @post = Post.find_by!(slug: params[:post_id])
  end
  
  def set_comment
    @comment = Comment.find(params[:id])
  end
  
  def comment_params
    params.require(:comment).permit(:username, :email, :body, :website)
  end
end 