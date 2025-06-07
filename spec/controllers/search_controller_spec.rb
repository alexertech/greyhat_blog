# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SearchController, type: :controller do
  let!(:published_post) { create(:post, title: 'Ruby on Rails Tutorial', draft: false) }
  let!(:draft_post) { create(:post, title: 'Draft Post', draft: true) }
  let!(:tag) { create(:tag, name: 'ruby') }
  let!(:tagged_post) { create(:post, title: 'Tagged Post', draft: false, tags: [tag]) }

  describe 'GET #index' do
    context 'when searching by query' do
      it 'returns published posts matching the query in title' do
        get :index, params: { q: 'Ruby' }
        
        expect(response).to have_http_status(:success)
        expect(assigns(:posts)).to include(published_post, tagged_post)
        expect(assigns(:posts)).not_to include(draft_post)
        expect(assigns(:query)).to eq('Ruby')
        expect(assigns(:tag)).to be_empty
      end

      it 'searches in post content' do
        published_post.update(body: ActionText::Content.new('This is about Python programming'))
        
        get :index, params: { q: 'Python' }
        
        expect(assigns(:posts)).to include(published_post)
      end

      it 'searches in tag names' do
        get :index, params: { q: 'ruby' }
        
        expect(assigns(:posts)).to include(tagged_post)
      end

      it 'returns distinct results when post matches multiple criteria' do
        published_post.update(title: 'Ruby Tutorial', body: ActionText::Content.new('Learning Ruby'))
        published_post.tags << tag
        
        get :index, params: { q: 'ruby' }
        
        expect(assigns(:posts).count { |p| p.id == published_post.id }).to eq(1)
      end

      it 'handles empty query gracefully' do
        get :index, params: { q: '' }
        
        expect(assigns(:posts)).to be_empty
        expect(assigns(:query)).to be_empty
      end

      it 'handles special characters in query' do
        get :index, params: { q: 'ruby & rails' }
        
        expect(response).to have_http_status(:success)
        expect(assigns(:posts)).to be_an(Array)
      end
    end

    context 'when searching by tag' do
      it 'returns posts with the specified tag' do
        get :index, params: { tag: 'ruby' }
        
        expect(response).to have_http_status(:success)
        expect(assigns(:posts)).to include(tagged_post)
        expect(assigns(:posts)).not_to include(published_post, draft_post)
        expect(assigns(:tag)).to eq('ruby')
        expect(assigns(:query)).to be_empty
      end

      it 'only returns published posts for tag search' do
        draft_tagged_post = create(:post, title: 'Draft Tagged', draft: true, tags: [tag])
        
        get :index, params: { tag: 'ruby' }
        
        expect(assigns(:posts)).to include(tagged_post)
        expect(assigns(:posts)).not_to include(draft_tagged_post)
      end

      it 'handles non-existent tag gracefully' do
        get :index, params: { tag: 'nonexistent' }
        
        expect(assigns(:posts)).to be_empty
        expect(assigns(:tag)).to eq('nonexistent')
      end

      it 'handles empty tag parameter' do
        get :index, params: { tag: '' }
        
        expect(assigns(:posts)).to be_empty
        expect(assigns(:tag)).to be_empty
      end
    end

    context 'when no search parameters provided' do
      it 'returns empty results' do
        get :index
        
        expect(response).to have_http_status(:success)
        expect(assigns(:posts)).to be_empty
        expect(assigns(:query)).to be_empty
        expect(assigns(:tag)).to be_empty
      end
    end

    context 'performance and limits' do
      it 'limits results to 20 posts' do
        25.times { |i| create(:post, title: "Ruby Post #{i}", draft: false) }
        
        get :index, params: { q: 'Ruby' }
        
        expect(assigns(:posts).size).to eq(20)
      end

      it 'orders results by creation date descending' do
        older_post = create(:post, title: 'Ruby Old', draft: false, created_at: 1.day.ago)
        newer_post = create(:post, title: 'Ruby New', draft: false, created_at: 1.hour.ago)
        
        get :index, params: { q: 'Ruby' }
        
        posts = assigns(:posts)
        newer_index = posts.index(newer_post)
        older_index = posts.index(older_post)
        expect(newer_index).to be < older_index
      end

      it 'includes necessary associations to avoid N+1 queries' do
        get :index, params: { q: 'Ruby' }
        
        expect { assigns(:posts).each { |post| post.image.attached?; post.tags.count } }
          .not_to exceed_query_limit(3) # Base query + image attachments + tags
      end
    end
  end
end