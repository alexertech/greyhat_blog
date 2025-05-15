# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DashboardsController, type: :controller do
  let(:user) { User.create(email: 'admin@example.com', password: 'password123456') }
  
  before do
    # Create required pages
    Page.create(id: 1, name: 'index')
    Page.create(id: 2, name: 'about')
    Page.create(id: 3, name: 'services')
  end

  describe 'GET #index' do
    context 'when user is authenticated' do
      before { login_user(user) }

      it 'returns a successful response' do
        get :index
        expect(response).to be_successful
      end

      it 'assigns all the required statistics variables' do
        # Create some test data
        post = Post.create(title: 'Test Post', body: 'Test Body')
        page = Page.find(1)
        
        # Create visits
        3.times { page.visits.create(ip_address: '127.0.0.1', user_agent: 'Test') }
        2.times { post.visits.create(ip_address: '127.0.0.1', user_agent: 'Test') }
        
        get :index
        
        expect(assigns(:total_visits)).to eq(5)
        expect(assigns(:visits_today)).to eq(5)
        expect(assigns(:visits_this_week)).to eq(5)
        expect(assigns(:most_visited_posts)).to include(post)
        expect(assigns(:home_visits)).to eq(3)
        expect(assigns(:posts_visits)).to eq(2)
      end
    end

    context 'when user is not authenticated' do
      it 'redirects to the login page' do
        get :index
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET #stats' do
    context 'when user is authenticated' do
      before { login_user(user) }

      it 'returns a successful response' do
        get :stats
        expect(response).to be_successful
      end

      it 'assigns statistics variables with default period' do
        get :stats
        expect(assigns(:period)).to eq(7)
        expect(assigns(:daily_visits)).to be_a(Hash)
        expect(assigns(:hourly_visits)).to be_a(Hash)
        expect(assigns(:page_visits)).to be_a(Hash)
        expect(assigns(:post_visits)).to be_a(Hash)
        expect(assigns(:referrer_counts)).to be_a(Hash)
      end

      it 'assigns statistics variables with custom period' do
        get :stats, params: { period: 30 }
        expect(assigns(:period)).to eq(30)
      end
    end

    context 'when user is not authenticated' do
      it 'redirects to the login page' do
        get :stats
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET #posts' do
    context 'when user is authenticated' do
      before { login_user(user) }

      it 'returns a successful response' do
        get :posts
        expect(response).to be_successful
      end

      it 'assigns most visited posts' do
        # Create some test posts
        post1 = Post.create(title: 'Post 1', body: 'Body 1')
        post2 = Post.create(title: 'Post 2', body: 'Body 2')
        
        # Add visits to make post1 more visited
        3.times { post1.visits.create(ip_address: '127.0.0.1', user_agent: 'Test') }
        1.times { post2.visits.create(ip_address: '127.0.0.1', user_agent: 'Test') }
        
        get :posts
        
        expect(assigns(:posts)).to eq([post1, post2])
      end
    end

    context 'when user is not authenticated' do
      it 'redirects to the login page' do
        get :posts
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end 