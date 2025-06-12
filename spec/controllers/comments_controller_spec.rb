# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CommentsController, type: :controller do
  let(:user) { create(:user) }
  let(:post_obj) { create(:post, user: user) }
  let!(:comment) { post_obj.comments.create!(username: 'Commenter', email: 'commenter@example.com', body: 'A test comment') }

  before do
    allow(Post).to receive(:find_by!).with(slug: post_obj.slug.to_s).and_return(post_obj)
    I18n.locale = :es
  end

  after do
    I18n.locale = I18n.default_locale
  end

  describe 'POST #create' do
    context 'with valid parameters' do
      let(:valid_attributes) { 
        { username: 'New User', email: 'user@example.com', body: 'New comment text', website: '' } 
      }

      it 'creates a new Comment' do
        expect {
          post :create, params: { post_id: post_obj.slug, comment: valid_attributes }
        }.to change(Comment, :count).by(1)
      end

      it 'redirects to the post with notice' do
        post :create, params: { post_id: post_obj.slug, comment: valid_attributes }
        expect(response).to redirect_to(post_path(post_obj))
        expect(flash[:notice]).to eq('¡Gracias por tu comentario! Será revisado por nuestro equipo antes de ser publicado.')
      end
    end

    context 'with invalid parameters' do
      let(:invalid_attributes) { 
        { username: '', email: 'invalid-email', body: '', website: '' } 
      }

      it 'does not create a new comment' do
        expect {
          post :create, params: { post_id: post_obj.slug, comment: invalid_attributes }
        }.not_to change(Comment, :count)
      end

      it 'redirects to the post with alert' do
        post :create, params: { post_id: post_obj.slug, comment: invalid_attributes }
        expect(response).to redirect_to(post_path(post_obj))
        expect(flash[:alert]).to be_present
      end
    end

    context 'with spam (website filled)' do
      let(:spam_attributes) { 
        { username: 'Spammer', email: 'spam@example.com', body: 'Spam comment', website: 'http://spam.com' } 
      }

      it 'does not create a new comment' do
        expect {
          post :create, params: { post_id: post_obj.slug, comment: spam_attributes }
        }.not_to change(Comment, :count)
      end
    end
  end

  describe 'DELETE #destroy' do
    context 'when not logged in' do
      it 'redirects to login page' do
        delete :destroy, params: { id: comment.id }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when logged in' do
      before do
        sign_in user
      end

      it 'destroys the requested comment' do
        expect {
          delete :destroy, params: { id: comment.id }
        }.to change(Comment, :count).by(-1)
      end

      it 'redirects to the comments dashboard' do
        delete :destroy, params: { id: comment.id }
        expect(response).to redirect_to(dashboards_comments_path)
        expect(flash[:notice]).to eq('Comentario eliminado correctamente.')
      end
    end
  end
end 