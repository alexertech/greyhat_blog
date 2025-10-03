# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DashboardBuilderService, type: :service do
  let(:user) { create(:user) }
  let(:service) { described_class.new(user) }

  describe '#build' do
    it 'returns a hash with all dashboard data' do
      result = service.build

      expect(result).to be_a(Hash)
      expect(result).to have_key(:total_visits)
      expect(result).to have_key(:most_visited_posts)
      expect(result).to have_key(:content_insights)
    end

    context 'with existing data' do
      let!(:post) { create(:post, :published, user: user) }
      let!(:visit) { create(:visit, visitable: post) }
      let!(:comment) { create(:comment, post: post, approved: true) }
      let!(:contact) { create(:contact) }

      it 'includes all required metrics' do
        result = service.build

        # Visit metrics
        expect(result[:total_visits]).to be >= 1
        expect(result[:visits_today]).to be >= 0
        expect(result[:visits_this_week]).to be >= 0
        expect(result[:visits_this_month]).to be >= 0

        # Content metrics
        expect(result[:total_posts]).to be >= 1
        expect(result[:published_posts]).to be >= 1
        expect(result[:comment_count]).to be >= 1
        expect(result[:total_contacts]).to be >= 1

        # Content performance
        expect(result[:most_visited_posts]).to be_present
        expect(result[:top_performing_posts]).to be_present
        expect(result[:trending_posts]).to be_present

        # Traffic sources
        expect(result[:social_media_visits]).to be >= 0
        expect(result[:search_engine_visits]).to be >= 0
        expect(result[:direct_visits]).to be >= 0

        # Charts
        expect(result[:daily_visits_chart]).to be_an(Array)
        expect(result[:hourly_visits_chart]).to be_a(Hash)

        # Analytics insights
        expect(result[:content_insights]).to be_present
        expect(result[:tag_performance]).to be_a(Hash)
        expect(result[:bounce_rate]).to be >= 0

        # Newsletter metrics
        expect(result[:funnel_data]).to be_a(Hash)
        expect(result[:newsletter_conversion_rate]).to be >= 0

        # Site health
        expect(result[:site_health]).to be_a(Hash)
        expect(result[:traffic_anomaly]).to be_a(Hash)

        # Legacy
        expect(result[:home_visits]).to be >= 0
        expect(result[:posts_visits]).to be >= 0
      end
    end

    context 'with no data' do
      before do
        Post.destroy_all
        Visit.destroy_all
        Comment.destroy_all
        Contact.destroy_all
      end

      it 'returns safe defaults for all metrics' do
        result = service.build

        expect(result[:total_visits]).to eq(0)
        expect(result[:total_posts]).to eq(0)
        expect(result[:comment_count]).to eq(0)
        expect(result[:most_visited_posts]).to be_empty
        expect(result[:funnel_data]).to be_a(Hash)
      end
    end

    context 'with custom period parameter' do
      let(:service) { described_class.new(user, period: 30) }

      it 'accepts custom period for analytics' do
        result = service.build

        expect(result).to have_key(:content_insights)
        expect(result).to have_key(:insights)
      end
    end
  end

  describe 'private methods' do
    describe '#visits_metrics' do
      context 'with visits from different time periods' do
        let!(:today_visit) { create(:visit, viewed_at: Time.zone.now) }
        let!(:week_visit) { create(:visit, viewed_at: 3.days.ago) }
        let!(:month_visit) { create(:visit, viewed_at: 15.days.ago) }
        let!(:old_visit) { create(:visit, viewed_at: 40.days.ago) }

        it 'correctly categorizes visits by time period' do
          result = service.send(:visits_metrics)

          expect(result[:total_visits]).to eq(4)
          # Visits are categorized into mutually exclusive buckets
          # today + week + month should be 3 (old_visit excluded)
          total_recent = result[:visits_today] + result[:visits_this_week] + result[:visits_this_month]
          expect(total_recent).to eq(3)
        end
      end

      context 'when database query fails' do
        before do
          allow(Visit).to receive(:group).and_raise(StandardError.new('DB Error'))
        end

        it 'falls back to simple queries' do
          result = service.send(:visits_metrics)

          expect(result).to have_key(:total_visits)
          expect(result).to have_key(:visits_today)
        end
      end
    end

    describe '#content_performance' do
      context 'with visited posts' do
        let!(:popular_post) { create(:post, :published, user: user) }
        let!(:other_post) { create(:post, :published, user: user) }

        before do
          create_list(:visit, 10, visitable: popular_post)
          create_list(:visit, 2, visitable: other_post)
        end

        it 'returns top performing posts' do
          result = service.send(:content_performance)

          expect(result[:most_visited_posts]).to be_present
          expect(result[:most_visited_posts].first).to eq(popular_post)
        end

        it 'returns trending posts based on recent activity' do
          result = service.send(:content_performance)

          expect(result[:trending_posts]).to be_present
        end
      end

      context 'with no visited posts' do
        let!(:recent_post) { create(:post, :published, user: user, created_at: 1.day.ago) }

        it 'falls back to recent published posts' do
          result = service.send(:content_performance)

          expect(result[:top_performing_posts]).to be_present
          expect(result[:trending_posts]).to be_present
        end
      end
    end

    describe '#content_metrics' do
      let!(:post1) { create(:post, :published, user: user) }
      let!(:post2) { create(:post, draft: true, user: user) }
      let!(:comment1) { create(:comment, post: post1, approved: true) }
      let!(:comment2) { create(:comment, post: post1, approved: false) }
      let!(:contact) { create(:contact) }

      it 'returns accurate counts for all content types' do
        result = service.send(:content_metrics)

        expect(result[:total_posts]).to eq(2)
        expect(result[:published_posts]).to eq(1)
        expect(result[:draft_posts]).to eq(1)
        expect(result[:comment_count]).to eq(2)
        expect(result[:approved_comment_count]).to eq(1)
        expect(result[:pending_comment_count]).to eq(1)
        expect(result[:total_contacts]).to eq(1)
      end
    end

    describe '#traffic_sources' do
      let!(:social_visit) { create(:visit, referer: 'https://facebook.com/page') }
      let!(:search_visit) { create(:visit, referer: 'https://google.com/search?q=test') }
      let!(:direct_visit) { create(:visit, referer: nil) }

      it 'categorizes traffic sources correctly' do
        result = service.send(:traffic_sources)

        expect(result[:social_media_visits]).to be >= 1
        expect(result[:search_engine_visits]).to be >= 1
        expect(result[:direct_visits]).to be >= 1
      end

      it 'includes top referrers preview' do
        result = service.send(:traffic_sources)

        expect(result[:top_referrers_preview]).to be_present
      end
    end

    describe '#charts_data' do
      let!(:visit1) { create(:visit, viewed_at: 1.day.ago) }
      let!(:visit2) { create(:visit, viewed_at: 2.days.ago) }

      it 'formats daily visits for charts' do
        result = service.send(:charts_data)

        expect(result[:daily_visits_chart]).to be_an(Array)
        expect(result[:daily_visits_chart].first).to be_an(Array)
        expect(result[:daily_visits_chart].first.size).to eq(2)
      end

      it 'includes hourly visits data' do
        result = service.send(:charts_data)

        expect(result[:hourly_visits_chart]).to be_a(Hash)
      end
    end

    describe '#newsletter_metrics' do
      it 'returns newsletter funnel data' do
        result = service.send(:newsletter_metrics)

        expect(result[:funnel_data]).to be_a(Hash)
        expect(result[:funnel_data]).to have_key(:index_visits)
        expect(result[:funnel_data]).to have_key(:newsletter_clicks)
      end

      it 'returns conversion rate' do
        result = service.send(:newsletter_metrics)

        expect(result[:newsletter_conversion_rate]).to be >= 0
      end
    end

    describe '#site_health_metrics' do
      it 'returns site health status' do
        result = service.send(:site_health_metrics)

        expect(result[:site_health]).to be_a(Hash)
        expect(result[:traffic_anomaly]).to be_a(Hash)
      end

      context 'when SiteHealth raises error' do
        before do
          allow(SiteHealth).to receive(:health_status).and_raise(StandardError)
        end

        it 'returns default health metrics' do
          result = service.send(:site_health_metrics)

          expect(result[:site_health][:status]).to eq('unknown')
        end
      end
    end

    describe '#legacy_metrics' do
      let!(:index_page) { create(:page, :index_page) }
      let!(:page_visit) { create(:visit, visitable: index_page) }
      let!(:post) { create(:post, user: user) }
      let!(:post_visit) { create(:visit, visitable: post) }

      it 'returns home and posts visit counts' do
        result = service.send(:legacy_metrics)

        expect(result[:home_visits]).to be >= 1
        expect(result[:posts_visits]).to be >= 1
      end
    end
  end
end
