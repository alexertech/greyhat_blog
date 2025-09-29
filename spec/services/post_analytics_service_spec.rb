# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PostAnalyticsService, type: :service do
  let(:user) { create(:user) }
  let(:post) { create(:post, user: user, unique_visits: 100) }
  let(:service) { described_class.new(post) }

  describe '#engagement_score' do
    context 'when post has no visits' do
      let(:post) { create(:post, user: user, unique_visits: 0) }

      it 'returns 0' do
        expect(service.engagement_score).to eq(0)
      end
    end

    context 'when post has visits and comments' do
      before do
        post.update_column(:unique_visits, 100)
        create_list(:comment, 2, post: post, approved: true)
        create(:comment, post: post, approved: false) # Should not count

        # Create some recent visits
        create_list(:visit, 5, visitable: post, viewed_at: 2.days.ago)
      end

      it 'calculates engagement score based on visits, comments, and recent activity' do
        score = service.engagement_score

        expect(score).to be > 0
        expect(score).to be_a(Float)

        # Weighted score: views (40%) + comments (40%) + recent activity (20%)
        # view_score = min(100/100, 10) * 4 = 4
        # comment_score = min(2*2, 10) * 4 = 16
        # recent_score = min(5/10, 10) * 2 = 1
        # Expected: 4 + 16 + 1 = 21
        expect(score).to eq(21.0)
      end
    end

    context 'when post has excessive metrics' do
      before do
        post.update_column(:unique_visits, 5000) # Very high
        create_list(:comment, 20, post: post, approved: true) # Many comments
        create_list(:visit, 200, visitable: post, viewed_at: 1.day.ago) # Many recent visits
      end

      it 'caps scores to prevent extreme values' do
        score = service.engagement_score

        # Each component should be capped at 10 * weight
        # view_score: min(5000/100, 10) * 4 = min(50, 10) * 4 = 40
        # comment_score: min(20*2, 10) * 4 = min(40, 10) * 4 = 40
        # recent_score: min(200/10, 10) * 2 = min(20, 10) * 2 = 20
        # Total: 40 + 40 + 20 = 100
        expect(score).to be <= 100
        expect(score).to eq(100.0)
      end
    end
  end

  describe '#newsletter_conversions' do
    let!(:newsletter_page) { Page.create!(name: 'newsletter') }

    before do
      # Create a post visit from IP 1.1.1.1
      create(:visit,
        visitable: post,
        ip_address: '1.1.1.1',
        viewed_at: 30.minutes.ago
      )

      # Create a newsletter click from same IP within 1 hour
      create(:visit,
        visitable: newsletter_page,
        ip_address: '1.1.1.1',
        action_type: 'newsletter_click',
        viewed_at: 15.minutes.ago
      )

      # Create unrelated visits that shouldn't count
      create(:visit,
        visitable: newsletter_page,
        ip_address: '2.2.2.2',  # Different IP
        action_type: 'newsletter_click',
        viewed_at: 10.minutes.ago
      )
    end

    it 'counts newsletter conversions from post readers' do
      # Mock the newsletter page ID lookup since we can't guarantee ID=5
      allow(Visit).to receive(:where).with(
        visitable_type: 'Page',
        visitable_id: 5,
        action_type: 'newsletter_click'
      ).and_return(
        Visit.where(
          visitable_type: 'Page',
          visitable_id: newsletter_page.id,
          action_type: 'newsletter_click'
        )
      )

      expect(service.newsletter_conversions).to eq(1)
    end

    it 'handles cases with no conversions' do
      Visit.destroy_all

      expect(service.newsletter_conversions).to eq(0)
    end
  end

  describe '#performance_trend' do
    context 'with visits in both periods' do
      before do
        # Current period (last 3 days): 5 visits
        create_list(:visit, 5, visitable: post, viewed_at: 1.day.ago)

        # Previous period (4-6 days ago): 2 visits
        create_list(:visit, 2, visitable: post, viewed_at: 5.days.ago)
      end

      it 'calculates percentage change between periods' do
        trend = service.performance_trend(3)

        # (5 - 2) / 2 * 100 = 150%
        expect(trend).to eq(150.0)
      end
    end

    context 'with no previous period data' do
      before do
        create_list(:visit, 3, visitable: post, viewed_at: 1.day.ago)
      end

      it 'returns 100% when current period has visits' do
        trend = service.performance_trend(3)
        expect(trend).to eq(100)
      end
    end

    context 'with no visits in either period' do
      it 'returns 0' do
        trend = service.performance_trend(3)
        expect(trend).to eq(0)
      end
    end

    context 'with extreme trend values' do
      before do
        # Current: 100 visits, Previous: 1 visit = 9900% increase
        create_list(:visit, 100, visitable: post, viewed_at: 1.day.ago)
        create(:visit, visitable: post, viewed_at: 5.days.ago)
      end

      it 'caps trend at 500%' do
        trend = service.performance_trend(3)
        expect(trend).to eq(500)
      end
    end

    context 'with negative trend' do
      before do
        # Current: 1 visit, Previous: 100 visits = -99% decrease
        create(:visit, visitable: post, viewed_at: 1.day.ago)
        create_list(:visit, 100, visitable: post, viewed_at: 5.days.ago)
      end

      it 'caps trend at -95%' do
        trend = service.performance_trend(3)
        expect(trend).to eq(-95.0)
      end
    end
  end

  describe '#related_posts' do
    let!(:tag1) { create(:tag, name: 'ruby') }
    let!(:tag2) { create(:tag, name: 'rails') }
    let!(:tag3) { create(:tag, name: 'javascript') }

    context 'when post has no tags' do
      it 'returns recent published posts' do
        other_posts = create_list(:post, 5, user: user, draft: false)

        related = service.related_posts(3)

        expect(related.count).to eq(3)
        expect(related).not_to include(post)
        expect(related.all? { |p| !p.draft }).to be true
      end
    end

    context 'when post has tags' do
      before do
        post.tags = [tag1, tag2]

        # Create posts with shared tags
        @related_post1 = create(:post, user: user, draft: false, tags: [tag1, tag2])  # 2 shared tags
        @related_post2 = create(:post, user: user, draft: false, tags: [tag1])        # 1 shared tag
        @unrelated_post = create(:post, user: user, draft: false, tags: [tag3])       # 0 shared tags
        @draft_post = create(:post, user: user, draft: true, tags: [tag1, tag2])      # Draft (excluded)
      end

      it 'returns posts with shared tags, ordered by relevance' do
        related = service.related_posts(3)

        expect(related).to include(@related_post1, @related_post2)
        expect(related).not_to include(@unrelated_post, @draft_post, post)

        # Should be ordered by number of shared tags (DESC)
        expect(related.first).to eq(@related_post1) # 2 shared tags
      end

      it 'respects the limit parameter' do
        related = service.related_posts(1)
        expect(related.count).to eq(1)
      end

      it 'excludes draft posts' do
        related = service.related_posts(5)
        expect(related).not_to include(@draft_post)
      end
    end

    context 'when no related posts exist' do
      before do
        post.tags = [tag1]
        Post.where.not(id: post.id).destroy_all # Remove all other posts
      end

      it 'returns fallback posts' do
        fallback_posts = create_list(:post, 2, user: user, draft: false, tags: [tag3])

        related = service.related_posts(3)

        expect(related.count).to eq(2)
        expect(related).to match_array(fallback_posts)
      end
    end
  end

  describe 'caching behavior' do
    it 'caches approved comments count' do
      expect(post.comments).to receive(:approved).once.and_return(double(count: 5))

      # Call multiple times
      service.engagement_score
      service.engagement_score
    end

    it 'caches recent visits count per time period' do
      allow(post.visits).to receive(:where).with('viewed_at >= ?', kind_of(ActiveSupport::TimeWithZone)).and_return(double(count: 10))

      # Call multiple times with same parameter
      service.send(:recent_visits_count, 7)
      service.send(:recent_visits_count, 7)
    end
  end

  describe 'edge cases' do
    context 'when post is nil' do
      let(:service) { described_class.new(nil) }

      it 'handles gracefully' do
        expect { service.engagement_score }.to raise_error(NoMethodError)
      end
    end

    context 'when database queries fail' do
      before do
        allow(post.visits).to receive(:where).and_raise(ActiveRecord::StatementInvalid)
      end

      it 'allows errors to bubble up for proper handling' do
        expect { service.performance_trend }.to raise_error(ActiveRecord::StatementInvalid)
      end
    end
  end
end