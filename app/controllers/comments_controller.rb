# frozen_string_literal: true

class CommentsController < ApplicationController
  before_action :authenticate_user!, except: [:create]
  before_action :set_post, only: [:create]
  before_action :set_comment, only: %i[destroy approve]

  def create
    @comment = @post.comments.new(comment_params)

    # Set the time the form was displayed for time-based bot detection
    @comment.form_displayed_at = session[:comment_form_displayed_at]

    # Rate limiting - track submissions
    session[:comment_submissions_count] ||= 0
    session[:comment_submissions_count] += 1

    # If too many submissions in a short time, reject
    if session[:comment_submissions_count] > 3
      @comment.errors.add(:base, 'Demasiados intentos. Por favor intente más tarde.')
      respond_to do |format|
        format.html { redirect_to post_path(@post), alert: @comment.errors.full_messages.to_sentence }
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace('comment_form',
                                                    partial: 'comments/form', locals: { post: @post, comment: @comment })
        end
      end
      return
    end

    respond_to do |format|
      if @comment.save
        # Reset submission counter on success
        session[:comment_submissions_count] = 0

        format.html do
          redirect_to post_path(@post),
                      notice: '¡Gracias por tu comentario! Será revisado por nuestro equipo antes de ser publicado.'
        end
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace('comment_form',
                                                    partial: 'comments/thank_you', locals: { post: @post })
        end
      else
        format.html { redirect_to post_path(@post), alert: @comment.errors.full_messages.to_sentence }
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace('comment_form',
                                                    partial: 'comments/form', locals: { post: @post, comment: @comment })
        end
      end
    end
  end

  def approve
    @comment.update(approved: true)

    respond_to do |format|
      format.html { redirect_to dashboards_comments_path, notice: 'Comentario aprobado correctamente.' }
      format.json { head :no_content }
    end
  end

  def destroy
    @comment.post
    @comment.destroy

    respond_to do |format|
      format.html { redirect_to dashboards_comments_path, notice: 'Comentario eliminado correctamente.' }
      format.json { head :no_content }
    end
  end

  private

  def set_post
    @post = Post.find_by!(slug: params[:post_id])

    # Store the current time in the session for time-based bot detection when showing a post
    session[:comment_form_displayed_at] = Time.current
  end

  def set_comment
    @comment = Comment.find(params[:id])
  end

  def comment_params
    params.require(:comment).permit(:username, :email, :body, :website)
  end
end
