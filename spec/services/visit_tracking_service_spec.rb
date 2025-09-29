# frozen_string_literal: true

require 'rails_helper'
require 'active_support/testing/time_helpers'

RSpec.configure do |config|
  config.include ActiveSupport::Testing::TimeHelpers
end

RSpec.describe VisitTrackingService, type: :service do
  let(:user) { create(:user) }
  let(:post) { create(:post, user: user, unique_visits: 0) }
  let(:page) { Page.create!(name: 'test-page') }
  let(:mock_request) do
    double('request',
           remote_ip: '192.168.1.1',
           user_agent: 'Mozilla/5.0 (Test Browser)',
           referer: 'https://example.com/referrer')
  end

  describe '#track_visit' do
    context 'for a post' do
      let(:service) { described_class.new(post, mock_request) }

      it 'creates a new visit record' do
        expect { service.track_visit }
          .to change { Visit.count }.by(1)
      end

      it 'records visit with correct attributes' do
        service.track_visit

        visit = Visit.last
        expect(visit.visitable).to eq(post)
        expect(visit.ip_address).to eq('192.168.1.1')
        expect(visit.user_agent).to eq('Mozilla/5.0 (Test Browser)')
        expect(visit.referer).to eq('https://example.com/referrer')
        expect(visit.action_type).to eq('page_view')
      end

      it 'increments unique_visits when no recent visit exists' do
        expect { service.track_visit }
          .to change { post.reload.unique_visits }.from(0).to(1)
      end

      it 'does not increment unique_visits for same IP within 24 hours' do
        # First visit
        service.track_visit
        expect(post.reload.unique_visits).to eq(1)

        # Second visit from same IP within 24 hours
        expect { service.track_visit }
          .not_to change { post.reload.unique_visits }
      end

      it 'increments unique_visits after 24 hours from same IP' do
        # First visit
        service.track_visit
        expect(post.reload.unique_visits).to eq(1)

        # Simulate visit after 24 hours by stubbing Time
        travel_to(25.hours.from_now) do
          expect { service.track_visit }
            .to change { post.reload.unique_visits }.by(1)
        end
      end

      it 'accepts custom action_type' do
        service.track_visit(action_type: 'newsletter_click')

        visit = Visit.last
        expect(visit.action_type).to eq('newsletter_click')
      end

      it 'always creates visit record even for duplicate IPs' do
        # First visit
        service.track_visit
        initial_count = Visit.count

        # Second visit should still create a record
        expect { service.track_visit }
          .to change { Visit.count }.by(1)
      end
    end

    context 'for a page' do
      let(:service) { described_class.new(page, mock_request) }

      it 'creates a visit record for page' do
        expect { service.track_visit }
          .to change { Visit.count }.by(1)

        visit = Visit.last
        expect(visit.visitable).to eq(page)
      end

      it 'increments unique_visits for pages (which do have the column)' do
        expect { service.track_visit }
          .to change { page.reload.unique_visits }.by(1)
      end
    end

    context 'with different IPs' do
      let(:service) { described_class.new(post, mock_request) }
      let(:other_request) do
        double('request',
               remote_ip: '192.168.1.2',
               user_agent: 'Other Browser',
               referer: 'https://other.com')
      end
      let(:other_service) { described_class.new(post, other_request) }

      it 'increments unique_visits for each different IP' do
        service.track_visit
        expect(post.reload.unique_visits).to eq(1)

        other_service.track_visit
        expect(post.reload.unique_visits).to eq(2)
      end
    end

    context 'when visitable is nil' do
      let(:service) { described_class.new(nil, mock_request) }

      it 'does not create any visits' do
        expect { service.track_visit }.not_to change { Visit.count }
      end

      it 'returns early without error' do
        expect { service.track_visit }.not_to raise_error
      end
    end

    context 'error handling' do
      let(:service) { described_class.new(post, mock_request) }

      context 'when Visit.create! fails' do
        before do
          allow(Visit).to receive(:create!).and_raise(ActiveRecord::RecordInvalid)
        end

        it 'logs the error and does not raise' do
          expect(Rails.logger).to receive(:warn).with(/Failed to track visit/)
          expect { service.track_visit }.not_to raise_error
        end

        it 'does not create a visit record' do
          allow(Rails.logger).to receive(:warn)
          expect { service.track_visit }.not_to change { Visit.count }
        end
      end

      context 'when unique_visits increment fails' do
        before do
          allow(post).to receive(:increment!).and_raise(ActiveRecord::RecordInvalid)
        end

        it 'logs the error and does not raise' do
          expect(Rails.logger).to receive(:warn).with(/Failed to track visit/)
          expect { service.track_visit }.not_to raise_error
        end
      end
    end

    context 'transaction rollback behavior' do
      let(:service) { described_class.new(post, mock_request) }

      it 'rolls back all changes if visit creation fails' do
        allow(Visit).to receive(:create!).and_raise(ActiveRecord::RecordInvalid)
        allow(Rails.logger).to receive(:warn)

        # Should not increment unique_visits if transaction fails
        expect { service.track_visit }
          .not_to change { post.reload.unique_visits }
      end
    end

    context 'bot detection integration' do
      let(:bot_request) do
        double('request',
               remote_ip: '192.168.1.1',
               user_agent: 'Googlebot/2.1',
               referer: nil)
      end
      let(:service) { described_class.new(post, bot_request) }

      it 'still tracks bot visits' do
        expect { service.track_visit }
          .to change { Visit.count }.by(1)

        visit = Visit.last
        expect(visit.user_agent).to eq('Googlebot/2.1')
      end
    end
  end

  describe 'private methods' do
    let(:service) { described_class.new(post, mock_request) }

    describe '#recent_visit_exists?' do
      it 'returns false when no recent visits' do
        result = service.send(:recent_visit_exists?)
        expect(result).to be false
      end

      it 'returns true when recent visit exists' do
        create(:visit, visitable: post, ip_address: '192.168.1.1', viewed_at: 12.hours.ago)
        result = service.send(:recent_visit_exists?)
        expect(result).to be true
      end

      it 'returns false when visit is older than 24 hours' do
        create(:visit, visitable: post, ip_address: '192.168.1.1', viewed_at: 25.hours.ago)
        result = service.send(:recent_visit_exists?)
        expect(result).to be false
      end
    end

    describe '#increment_unique_visits' do
      it 'calls increment! when visitable responds to unique_visits' do
        expect(post).to receive(:increment!).with(:unique_visits)
        service.send(:increment_unique_visits)
      end

      it 'calls increment! when page has unique_visits column' do
        page_service = described_class.new(page, mock_request)
        expect(page).to receive(:increment!).with(:unique_visits)
        page_service.send(:increment_unique_visits)
      end
    end

    describe '#create_visit_record' do
      it 'creates visit with specified action_type' do
        service.send(:create_visit_record, 'newsletter_click')

        visit = Visit.last
        expect(visit.action_type).to eq('newsletter_click')
        expect(visit.visitable).to eq(post)
        expect(visit.ip_address).to eq('192.168.1.1')
      end
    end
  end
end