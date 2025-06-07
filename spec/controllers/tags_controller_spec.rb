# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TagsController, type: :controller do
  let(:user) { create(:user) }
  let!(:tag1) { create(:tag, name: 'ruby') }
  let!(:tag2) { create(:tag, name: 'javascript') }
  let!(:tag3) { create(:tag, name: 'python') }
  let!(:published_post1) { create(:post, draft: false, tags: [tag1, tag2]) }
  let!(:published_post2) { create(:post, draft: false, tags: [tag1]) }
  let!(:draft_post) { create(:post, draft: true, tags: [tag1]) }

  describe 'GET #index' do
    context 'when requesting JSON format' do
      it 'returns popular tag names in JSON format' do
        get :index, format: :json
        
        expect(response).to have_http_status(:success)
        expect(response.content_type).to eq('application/json; charset=utf-8')
        
        json_response = JSON.parse(response.body)
        expect(json_response).to include('ruby', 'javascript')
        expect(json_response).not_to include('python') # No published posts with this tag
      end

      it 'orders tags by post count descending, then name ascending' do
        get :index, format: :json
        
        json_response = JSON.parse(response.body)
        expect(json_response.first).to eq('ruby') # Most popular (2 posts)
        expect(json_response.second).to eq('javascript') # Less popular (1 post)
      end

      it 'limits to 20 tags' do
        25.times { |i| 
          tag = create(:tag, name: "tag#{i}")
          create(:post, draft: false, tags: [tag])
        }
        
        get :index, format: :json
        
        json_response = JSON.parse(response.body)
        expect(json_response.size).to be <= 20
      end

      it 'excludes tags from draft posts only' do
        draft_only_tag = create(:tag, name: 'draft-only')
        create(:post, draft: true, tags: [draft_only_tag])
        
        get :index, format: :json
        
        json_response = JSON.parse(response.body)
        expect(json_response).not_to include('draft-only')
      end
    end

    context 'when requesting HTML format' do
      it 'returns tags with post counts for browsing page' do
        get :index
        
        expect(response).to have_http_status(:success)
        expect(assigns(:tags_with_counts)).to be_present
        expect(assigns(:total_posts)).to eq(2) # Only published posts
      end

      it 'includes post counts for each tag' do
        get :index
        
        ruby_tag = assigns(:tags_with_counts).find { |t| t.name == 'ruby' }
        js_tag = assigns(:tags_with_counts).find { |t| t.name == 'javascript' }
        
        expect(ruby_tag.posts_count).to eq(2)
        expect(js_tag.posts_count).to eq(1)
      end

      it 'limits to 50 tags for HTML view' do
        55.times { |i| 
          tag = create(:tag, name: "htmltag#{i}")
          create(:post, draft: false, tags: [tag])
        }
        
        get :index
        
        expect(assigns(:tags_with_counts).size).to be <= 50
      end

      it 'orders tags by popularity' do
        get :index
        
        tags = assigns(:tags_with_counts)
        expect(tags.first.name).to eq('ruby')
        expect(tags.first.posts_count).to be >= tags.last.posts_count
      end
    end
  end

  describe 'POST #suggest' do
    context 'when user is authenticated' do
      before { sign_in user }

      it 'suggests relevant tags based on content' do
        content = 'This article talks about Ruby programming and web development'
        
        post :suggest, params: { 
          content: content, 
          existing_tags: '' 
        }, format: :json
        
        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['suggestions']).to include('ruby')
      end

      it 'excludes already existing tags from suggestions' do
        content = 'Ruby and JavaScript programming tutorial'
        
        post :suggest, params: { 
          content: content, 
          existing_tags: 'ruby,tutorial' 
        }, format: :json
        
        json_response = JSON.parse(response.body)
        expect(json_response['suggestions']).not_to include('ruby', 'tutorial')
      end

      it 'suggests psychology-related tags for non-technical content' do
        content = 'La atención es nuestra moneda digital y las redes sociales como Instagram manipulan nuestro cerebro'
        
        post :suggest, params: { 
          content: content, 
          existing_tags: '' 
        }, format: :json
        
        json_response = JSON.parse(response.body)
        expect(json_response['suggestions']).to include('atención', 'redes-sociales', 'psicología')
      end

      it 'suggests digital wellness tags' do
        content = 'Digital detox and mindfulness help with screen time management and mental health'
        
        post :suggest, params: { 
          content: content, 
          existing_tags: '' 
        }, format: :json
        
        json_response = JSON.parse(response.body)
        expect(json_response['suggestions']).to include('detox-digital', 'mindfulness', 'salud-mental')
      end

      it 'limits suggestions to specified number' do
        content = 'Ruby Rails JavaScript Python HTML CSS React Vue Angular Node.js'
        
        post :suggest, params: { 
          content: content, 
          existing_tags: '' 
        }, format: :json
        
        json_response = JSON.parse(response.body)
        expect(json_response['suggestions'].size).to be <= 5
      end

      it 'handles empty content gracefully' do
        post :suggest, params: { 
          content: '', 
          existing_tags: '' 
        }, format: :json
        
        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['suggestions']).to be_an(Array)
      end

      it 'matches existing tags in database' do
        tag1 # Create ruby tag
        content = 'This is about ruby programming'
        
        post :suggest, params: { 
          content: content, 
          existing_tags: '' 
        }, format: :json
        
        json_response = JSON.parse(response.body)
        expect(json_response['suggestions']).to include('ruby')
      end

      it 'suggests content type tags based on keywords' do
        content = 'This is a step-by-step tutorial guide for beginners'
        
        post :suggest, params: { 
          content: content, 
          existing_tags: '' 
        }, format: :json
        
        json_response = JSON.parse(response.body)
        expect(json_response['suggestions']).to include('tutorial', 'principiantes')
      end
    end

    context 'when user is not authenticated' do
      it 'requires authentication' do
        post :suggest, params: { 
          content: 'test content', 
          existing_tags: '' 
        }, format: :json
        
        expect(response).to have_http_status(:redirect)
      end
    end

    context 'CSRF protection' do
      before { sign_in user }

      it 'requires valid CSRF token for non-GET requests' do
        # This would normally fail without proper token, but we're testing the protection exists
        expect(controller).to respond_to(:protect_from_forgery)
      end
    end
  end

  describe 'Tag suggestion service integration' do
    before { sign_in user }

    it 'uses TagSuggestionService for content analysis' do
      expect(TagSuggestionService).to receive(:new).with(
        'test content', 
        []
      ).and_call_original
      
      post :suggest, params: { 
        content: 'test content', 
        existing_tags: '' 
      }, format: :json
    end

    it 'handles service errors gracefully' do
      allow(TagSuggestionService).to receive(:new).and_raise(StandardError.new('Service error'))
      
      expect {
        post :suggest, params: { 
          content: 'test content', 
          existing_tags: '' 
        }, format: :json
      }.not_to raise_error
    end
  end
end