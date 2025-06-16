# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Post, type: :model do
  describe 'validations' do
    it 'is valid with valid attributes' do
      user = create(:user)
      post = Post.new(title: 'Test Post', body: 'Test Body', user: user)
      expect(post).to be_valid
    end

    it 'is not valid without a title' do
      user = create(:user)
      post = Post.new(body: 'Test Body', user: user)
      expect(post).not_to be_valid
    end

    it 'is not valid without a body' do
      user = create(:user)
      post = Post.new(title: 'Test Post', user: user)
      expect(post).not_to be_valid
    end

    it 'is not valid without a user' do
      post = Post.new(title: 'Test Post', body: 'Test Body')
      expect(post).not_to be_valid
    end
  end

  describe 'associations' do
    it 'belongs to user' do
      association = Post.reflect_on_association(:user)
      expect(association.macro).to eq :belongs_to
    end

    it 'has many visits' do
      association = Post.reflect_on_association(:visits)
      expect(association.macro).to eq :has_many
    end

    it 'has many comments' do
      association = Post.reflect_on_association(:comments)
      expect(association.macro).to eq :has_many
    end

    it 'has many tags through post_tags' do
      association = Post.reflect_on_association(:tags)
      expect(association.macro).to eq :has_many
      expect(association.options[:through]).to eq :post_tags
    end
  end
  
  context 'post' do
    xit 'creates a post with attachment' do
      user = create(:user)
      subject = Post.new
      subject.user = user
      subject.title = 'title'
      subject.body =  'body'
      subject.image.attach(
        io: File.open(Rails.root.join('spec', 'fixtures', 'files', 'image.jpg')),
        filename: 'image.jpg',
        content_type: 'image/jpeg'
      )
      subject.save!

      expect(subject).to be_valid
      expect(subject.image).to be_attached
      expect(subject.image).to be_an_instance_of(ActiveStorage::Attached::One)
      expect(subject.image.blob.filename).not_to be_nil
    end
    
    it 'defaults to not being a draft' do
      user = create(:user)
      subject = Post.create(title: 'Test Post', body: 'Test Body', user: user)
      expect(subject.draft).to be(false)
    end
    
    describe 'scopes' do
      before do
        user = create(:user)
        Post.create(title: 'Published Post 1', body: 'Content', draft: false, user: user)
        Post.create(title: 'Published Post 2', body: 'Content', draft: false, user: user)
        Post.create(title: 'Draft Post 1', body: 'Content', draft: true, user: user)
        Post.create(title: 'Draft Post 2', body: 'Content', draft: true, user: user)
      end
      
      it 'returns only published posts with published scope' do
        expect(Post.published.count).to eq(2)
        expect(Post.published.map(&:title)).to include('Published Post 1', 'Published Post 2')
        expect(Post.published.map(&:title)).not_to include('Draft Post 1', 'Draft Post 2')
      end
      
      it 'returns only draft posts with drafts scope' do
        expect(Post.drafts.count).to eq(2)
        expect(Post.drafts.map(&:title)).to include('Draft Post 1', 'Draft Post 2')
        expect(Post.drafts.map(&:title)).not_to include('Published Post 1', 'Published Post 2')
      end
    end
  end
  
  describe 'performance methods' do
    let(:user) { create(:user) }
    let(:post) { Post.create(title: 'Test Post', body: 'Test Body', user: user, unique_visits: 10) }
    
    describe '#total_visits' do
      it 'uses visits_count counter cache when available' do
        post.update_column(:visits_count, 25)
        expect(post.total_visits).to eq(25)
      end
      
      it 'returns 0 when visits_count is 0' do
        post.update_column(:visits_count, 0)
        expect(post.total_visits).to eq(0)
      end
    end
    
    describe '#unique_visits' do
      it 'uses unique_visits field when available' do
        expect(post.unique_visits).to eq(10)
      end
      
      it 'falls back to distinct count when field is nil' do
        post.update_column(:unique_visits, nil)
        # Create some visits with different IPs
        Visit.create(visitable: post, ip_address: '1.1.1.1', user_agent: 'test', action_type: 'page_view')
        Visit.create(visitable: post, ip_address: '2.2.2.2', user_agent: 'test', action_type: 'page_view')
        Visit.create(visitable: post, ip_address: '1.1.1.1', user_agent: 'test', action_type: 'page_view') # duplicate IP
        
        expect(post.unique_visits).to eq(2) # Only count distinct IPs
      end
    end
    
    describe '#engagement_score' do
      it 'calculates engagement score based on visits and comments' do
        post.update_column(:unique_visits, 100)
        post.comments.create(body: 'Test comment', username: 'testuser', email: 'test@example.com', approved: true, post: post)
        
        # Weighted score: views (40%) + comments (40%) + recent activity (20%)
        # view_score = min(100/100, 10) * 4 = 4
        # comment_score = min(1*2, 10) * 4 = 8  
        # recent_score = based on recent_visits
        score = post.engagement_score
        expect(score).to be > 0
        expect(score).to be_a(Float)
      end
      
      it 'returns 0 when no visits' do
        post.update_column(:unique_visits, 0)
        expect(post.engagement_score).to eq(0)
      end
    end
    
    describe '#performance_trend' do
      it 'calculates trend based on recent vs previous visits' do
        # Create visits in different time periods
        3.days.ago.tap do |time|
          allow(Time).to receive(:current).and_return(time)
          Visit.create(visitable: post, ip_address: '1.1.1.1', user_agent: 'test', viewed_at: time)
        end
        
        1.day.ago.tap do |time|
          allow(Time).to receive(:current).and_return(time)
          Visit.create(visitable: post, ip_address: '2.2.2.2', user_agent: 'test', viewed_at: time)
          Visit.create(visitable: post, ip_address: '3.3.3.3', user_agent: 'test', viewed_at: time)
        end
        
        allow(Time).to receive(:current).and_call_original
        
        trend = post.performance_trend
        expect(trend).to be_a(Numeric)
        expect(trend).to be >= -95 # Capped at -95%
        expect(trend).to be <= 500 # Capped at +500%
      end
    end
  end
  
  describe 'counter cache functionality' do
    let(:user) { create(:user) }
    let(:post) { Post.create(title: 'Test Post', body: 'Test Body', user: user) }
    
    it 'increments visits_count when visit is created' do
      expect {
        Visit.create(visitable: post, ip_address: '1.1.1.1', user_agent: 'test', action_type: 'page_view')
      }.to change { post.reload.visits_count }.by(1)
    end
    
    it 'decrements visits_count when visit is destroyed' do
      visit = Visit.create(visitable: post, ip_address: '1.1.1.1', user_agent: 'test', action_type: 'page_view')
      
      expect {
        visit.destroy
      }.to change { post.reload.visits_count }.by(-1)
    end
  end
  
  describe 'background job integration' do
    let(:user) { create(:user) }
    let(:post) { Post.create(title: 'Test Post', body: 'Test Body', user: user) }
    
    it 'enqueues ImageVariantJob when image is attached' do
      expect {
        post.image.attach(
          io: File.open(Rails.root.join('spec', 'fixtures', 'test_image.jpg')),
          filename: 'test_image.jpg',
          content_type: 'image/jpeg'
        )
        post.save
      }.to have_enqueued_job(ImageVariantJob).with(post.id)
    end
    
    it 'does not enqueue job when no image is attached' do
      expect {
        post.update(title: 'Updated Title')
      }.not_to have_enqueued_job(ImageVariantJob)
    end
  end
  
  describe 'class methods' do
    let(:user) { create(:user) }
    
    describe '.total_unique_visits' do
      it 'sums unique_visits from all posts' do
        Post.create(title: 'Post 1', body: 'Body', user: user, unique_visits: 10)
        Post.create(title: 'Post 2', body: 'Body', user: user, unique_visits: 15)
        Post.create(title: 'Post 3', body: 'Body', user: user, unique_visits: 5)
        
        expect(Post.total_unique_visits).to eq(30)
      end
    end
    
    describe '.most_visited' do
      it 'returns posts ordered by visits_count' do
        post1 = Post.create(title: 'Post 1', body: 'Body', user: user, draft: false, visits_count: 5)
        post2 = Post.create(title: 'Post 2', body: 'Body', user: user, draft: false, visits_count: 15)
        post3 = Post.create(title: 'Post 3', body: 'Body', user: user, draft: false, visits_count: 10)
        draft_post = Post.create(title: 'Draft', body: 'Body', user: user, draft: true, visits_count: 20)
        
        most_visited = Post.most_visited(2)
        expect(most_visited).to eq([post2, post3])
        expect(most_visited).not_to include(draft_post) # Should exclude drafts
      end
    end
  end
end
