# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PostsController, type: :controller do
  let(:user) { User.create(email: 'test@example.com', password: 'password123456', public_name: 'Test User') }
  
  let(:valid_attributes) {
    {
      title: 'Test Post',
      body: 'This is a test post body',
      user_id: user.id
    }
  }

  let(:invalid_attributes) {
    {
      title: '',
      body: '',
      user_id: nil
    }
  }

  describe 'GET #index' do
    context 'when user is authenticated' do
      before { login_user(user) }

      it 'returns a successful response' do
        get :index
        expect(response).to be_successful
      end

      it 'assigns all posts as @posts' do
        post = Post.create(valid_attributes)
        get :index
        expect(assigns(:posts)).to eq([post])
      end
    end

    context 'when user is not authenticated' do
      it 'redirects to the login page' do
        get :index
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET #list' do
    it 'returns a successful response' do
      get :list
      expect(response).to be_successful
    end

    it 'assigns all published posts ordered by creation date DESC as @posts' do
      post1 = Post.create(valid_attributes.merge(title: 'Post 1', draft: false))
      post2 = Post.create(valid_attributes.merge(title: 'Post 2', draft: false))
      draft_post = Post.create(valid_attributes.merge(title: 'Draft Post', draft: true))
      get :list
      expect(assigns(:posts).to_a).to eq([post2, post1])
      expect(assigns(:posts)).not_to include(draft_post)
    end

    it 'uses cached total_published_visits for performance' do
      # Create posts with visit counts
      post1 = Post.create(valid_attributes.merge(title: 'Post 1', draft: false, visits_count: 10))
      post2 = Post.create(valid_attributes.merge(title: 'Post 2', draft: false, visits_count: 5))
      
      # Mock Rails.cache to verify caching behavior
      allow(Rails.cache).to receive(:fetch).with('total_published_visits', expires_in: 1.hour).and_return(15)
      
      get :list
      expect(assigns(:total_published_visits)).to eq(15)
      expect(Rails.cache).to have_received(:fetch).with('total_published_visits', expires_in: 1.hour)
    end

    it 'computes excerpts and reading times to avoid N+1 queries' do
      post = Post.create(valid_attributes.merge(
        title: 'Test Post', 
        draft: false,
        body: 'This is a long body with many words. ' * 50 # 300 words
      ))
      
      get :list
      
      # Check that excerpts are pre-computed
      expect(assigns(:excerpts)).to have_key(post.id)
      expect(assigns(:excerpts)[post.id]).to be_present
      expect(assigns(:excerpts)[post.id].length).to be <= 203 # 200 + "..."
      
      # Check that reading times are pre-computed
      expect(assigns(:reading_times)).to have_key(post.id)
      expect(assigns(:reading_times)[post.id]).to eq(2) # ~300 words / 200 = 1.5, ceil = 2
    end

    it 'includes necessary associations to prevent N+1 queries' do
      post = Post.create(valid_attributes.merge(title: 'Test Post', draft: false))
      tag = Tag.create(name: 'test-tag')
      post.tags << tag
      
      # Mock ActiveRecord to track query count
      query_count = 0
      allow(ActiveRecord::Base.connection).to receive(:execute) do |sql|
        query_count += 1 if sql.is_a?(String) && sql.include?('SELECT')
        # Call original method
        ActiveRecord::Base.connection.execute(sql)
      end
      
      get :list
      
      # Should have loaded posts with includes, not trigger additional queries
      expect(assigns(:posts).first.tags.loaded?).to be true
      expect(assigns(:posts).first.association(:image_attachment).loaded?).to be true
      expect(assigns(:posts).first.association(:rich_text_body).loaded?).to be true
    end

    it 'handles empty results gracefully' do
      get :list
      expect(assigns(:posts)).to be_empty
      expect(assigns(:total_published_visits)).to eq(0)
      expect(assigns(:excerpts)).to eq({})
      expect(assigns(:reading_times)).to eq({})
    end
  end

  describe 'GET #show' do
    it 'returns a successful response for a published post' do
      post = Post.create(valid_attributes.merge(draft: false))
      get :show, params: { id: post.slug }
      expect(response).to be_successful
    end
    
    it 'redirects to root for a draft post when not logged in' do
      post = Post.create(valid_attributes.merge(draft: true))
      get :show, params: { id: post.slug }
      expect(response).to redirect_to(root_path)
    end
    
    it 'returns a successful response for a draft post when logged in' do
      login_user(user)
      post = Post.create(valid_attributes.merge(draft: true))
      get :show, params: { id: post.slug }
      expect(response).to be_successful
    end

    it 'tracks the visit' do
      post = Post.create(valid_attributes.merge(unique_visits: 0))
      expect {
        get :show, params: { id: post.slug }
      }.to change { post.reload.unique_visits }.by(1)
      
      expect(post.visits.count).to eq(1)
      expect(post.visits.last.ip_address).to be_present
      expect(post.visits.last.user_agent).to be_present
    end

    it 'does not increment unique visits for same IP within 24 hours' do
      post = Post.create(valid_attributes.merge(unique_visits: 0))
      
      # First visit
      get :show, params: { id: post.slug }
      expect(post.reload.unique_visits).to eq(1)
      
      # Second visit from same IP should not increment unique_visits
      expect {
        get :show, params: { id: post.slug }
      }.not_to change { post.reload.unique_visits }
      
      # But should still create a visit record
      expect(post.visits.count).to eq(2)
    end
  end

  describe 'GET #new' do
    context 'when user is authenticated' do
      before { login_user(user) }

      it 'returns a successful response' do
        get :new
        expect(response).to be_successful
      end

      it 'assigns a new post as @post' do
        get :new
        expect(assigns(:post)).to be_a_new(Post)
      end
    end

    context 'when user is not authenticated' do
      it 'redirects to the login page' do
        get :new
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET #edit' do
    context 'when user is authenticated' do
      before { login_user(user) }

      it 'returns a successful response' do
        post = Post.create(valid_attributes)
        get :edit, params: { id: post.slug }
        expect(response).to be_successful
      end

      it 'assigns the requested post as @post' do
        post = Post.create(valid_attributes)
        get :edit, params: { id: post.slug }
        expect(assigns(:post)).to eq(post)
      end
    end

    context 'when user is not authenticated' do
      it 'redirects to the login page' do
        post = Post.create(valid_attributes)
        get :edit, params: { id: post.slug }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'POST #create' do
    context 'when user is authenticated' do
      before { login_user(user) }

      context 'with valid params' do
        it 'creates a new Post' do
          expect {
            post :create, params: { post: valid_attributes }
          }.to change(Post, :count).by(1)
        end

        it 'assigns a newly created post as @post' do
          post :create, params: { post: valid_attributes }
          expect(assigns(:post)).to be_a(Post)
          expect(assigns(:post)).to be_persisted
        end

        it 'redirects to the created post' do
          post :create, params: { post: valid_attributes }
          expect(response).to redirect_to(Post.last)
        end
      end

      context 'with invalid params' do
        it 'does not create a new Post and re-renders the new template' do
          expect {
            post :create, params: { post: invalid_attributes }
          }.to change(Post, :count).by(0)
          expect(response).to render_template('new')
        end
      end
    end

    context 'when user is not authenticated' do
      it 'redirects to the login page' do
        post :create, params: { post: valid_attributes }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'PUT #update' do
    context 'when user is authenticated' do
      before { login_user(user) }

      context 'with valid params' do
        let(:new_attributes) {
          { title: 'Updated Title', body: 'Updated body content' }
        }

        it 'updates the requested post' do
          post = Post.create(valid_attributes)
          put :update, params: { id: post.slug, post: new_attributes }
          post.reload
          expect(post.title).to eq('Updated Title')
          expect(post.slug).to eq('updated-title')
          expect(post.body.to_plain_text.strip).to eq('Updated body content')
        end

        it 'assigns the requested post as @post' do
          post = Post.create(valid_attributes)
          put :update, params: { id: post.slug, post: new_attributes }
          expect(assigns(:post)).to eq(post)
        end

        it 'redirects to the post with updated slug' do
          post = Post.create(valid_attributes)
          put :update, params: { id: post.slug, post: new_attributes }
          post.reload
          expect(response).to redirect_to(post)
        end
      end

      context 'with invalid params' do
        it 'does not update the post and re-renders the edit template' do
          post = Post.create(valid_attributes)
          put :update, params: { id: post.slug, post: invalid_attributes }
          expect(assigns(:post)).to eq(post)
          expect(response).to render_template('edit')
        end
      end
    end

    context 'when user is not authenticated' do
      it 'redirects to the login page' do
        post = Post.create(valid_attributes)
        put :update, params: { id: post.slug, post: { title: 'Updated' } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'DELETE #destroy' do
    context 'when user is authenticated' do
      before { login_user(user) }

      it 'destroys the requested post' do
        post = Post.create(valid_attributes)
        expect {
          delete :destroy, params: { id: post.slug }
        }.to change(Post, :count).by(-1)
      end

      it 'redirects to the posts list' do
        post = Post.create(valid_attributes)
        delete :destroy, params: { id: post.slug }
        expect(response).to redirect_to(posts_url)
      end
    end

    context 'when user is not authenticated' do
      it 'redirects to the login page' do
        post = Post.create(valid_attributes)
        delete :destroy, params: { id: post.slug }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end 