# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UsersController, type: :controller do
  let(:user) { create(:user) }
  let(:valid_attributes) do
    {
      email: 'test@example.com',
      password: 'password123456',
      public_name: 'Test User',
      description: 'Test description'
    }
  end

  let(:invalid_attributes) do
    {
      email: '',
      password: '',
      public_name: ''
    }
  end

  before do
    sign_in user
  end

  describe 'GET #index' do
    it 'returns a success response' do
      get :index
      expect(response).to be_successful
    end

    it 'assigns all users to @users' do
      user1 = create(:user)
      user2 = create(:user)
      get :index
      expect(assigns(:users)).to include(user, user1, user2)
    end
  end

  describe 'GET #show' do
    it 'returns a success response' do
      get :show, params: { id: user.to_param }
      expect(response).to be_successful
    end

    it 'assigns the requested user to @user' do
      get :show, params: { id: user.to_param }
      expect(assigns(:user)).to eq(user)
    end
  end

  describe 'GET #new' do
    it 'returns a success response' do
      get :new
      expect(response).to be_successful
    end

    it 'assigns a new user to @user' do
      get :new
      expect(assigns(:user)).to be_a_new(User)
    end
  end

  describe 'GET #edit' do
    it 'returns a success response' do
      get :edit, params: { id: user.to_param }
      expect(response).to be_successful
    end

    it 'assigns the requested user to @user' do
      get :edit, params: { id: user.to_param }
      expect(assigns(:user)).to eq(user)
    end
  end

  describe 'POST #create' do
    context 'with valid params' do
      it 'creates a new User' do
        expect {
          post :create, params: { user: valid_attributes }
        }.to change(User, :count).by(1)
      end

      it 'redirects to the users list' do
        post :create, params: { user: valid_attributes }
        expect(response).to redirect_to(users_path)
      end
    end

    context 'with invalid params' do
      it 'does not create a new User' do
        expect {
          post :create, params: { user: invalid_attributes }
        }.not_to change(User, :count)
      end

      it 'renders the new template' do
        post :create, params: { user: invalid_attributes }
        expect(response).to render_template(:new)
      end
    end
  end

  describe 'PUT #update' do
    context 'with valid params' do
      let(:new_attributes) do
        {
          public_name: 'Updated Name',
          description: 'Updated description'
        }
      end

      it 'updates the requested user' do
        put :update, params: { id: user.to_param, user: new_attributes }
        user.reload
        expect(user.public_name).to eq('Updated Name')
        expect(user.description).to eq('Updated description')
      end

      it 'redirects to the users list' do
        put :update, params: { id: user.to_param, user: new_attributes }
        expect(response).to redirect_to(users_path)
      end
    end

    context 'with invalid params' do
      it 'renders the edit template' do
        put :update, params: { id: user.to_param, user: invalid_attributes }
        expect(response).to render_template(:edit)
      end
    end
  end

  describe 'DELETE #destroy' do
    context 'when user has no posts' do
      it 'destroys the requested user' do
        user_to_delete = create(:user)
        expect {
          delete :destroy, params: { id: user_to_delete.to_param }
        }.to change(User, :count).by(-1)
      end

      it 'redirects to the users list' do
        user_to_delete = create(:user)
        delete :destroy, params: { id: user_to_delete.to_param }
        expect(response).to redirect_to(users_path)
      end
    end

    context 'when user has posts' do
      it 'does not destroy the user' do
        user_with_posts = create(:user)
        create(:post, user: user_with_posts)
        expect {
          delete :destroy, params: { id: user_with_posts.to_param }
        }.not_to change(User, :count)
      end

      it 'redirects to users list with alert' do
        user_with_posts = create(:user)
        create(:post, user: user_with_posts)
        delete :destroy, params: { id: user_with_posts.to_param }
        expect(response).to redirect_to(users_path)
        expect(flash[:alert]).to be_present
      end
    end
  end
end