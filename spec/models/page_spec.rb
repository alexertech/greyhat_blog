# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Page, type: :model do
  describe 'associations' do
    it 'has many visits' do
      expect(Page.reflect_on_association(:visits).macro).to eq(:has_many)
    end
    
    it 'has dependent destroy on visits' do
      expect(Page.reflect_on_association(:visits).options[:dependent]).to eq(:destroy)
    end
  end

  describe '#recent_visits' do
    it 'returns count of visits within the specified days' do
      page = Page.create(name: 'test-page')
      
      # Create visits within the specified time range
      3.times do
        page.visits.create(
          ip_address: '127.0.0.1',
          user_agent: 'RSpec',
          viewed_at: 3.days.ago
        )
      end
      
      # Create visits outside the specified time range
      2.times do
        page.visits.create(
          ip_address: '127.0.0.1',
          user_agent: 'RSpec',
          viewed_at: 10.days.ago
        )
      end
      
      expect(page.recent_visits(7)).to eq(3)
      expect(page.recent_visits(2)).to eq(0)
    end
  end

  describe '.visits_by_day' do
    it 'returns a hash of visits grouped by day' do
      page1 = Page.create(name: 'page-1')
      page2 = Page.create(name: 'page-2')
      
      # Create visits on different days
      page1.visits.create(
        ip_address: '127.0.0.1',
        user_agent: 'RSpec',
        viewed_at: Date.today
      )
      
      2.times do
        page2.visits.create(
          ip_address: '127.0.0.1',
          user_agent: 'RSpec',
          viewed_at: Date.today
        )
      end
      
      page1.visits.create(
        ip_address: '127.0.0.1',
        user_agent: 'RSpec',
        viewed_at: 1.day.ago
      )
      
      result = Page.visits_by_day
      
      expect(result).to be_a(Hash)
      
      # Check for today's visits
      today_count = result.find { |date, _| date.to_date == Date.today }
      expect(today_count).to be_present
      expect(today_count[1]).to eq(3)
      
      # Check for yesterday's visits
      yesterday_count = result.find { |date, _| date.to_date == 1.day.ago.to_date }
      expect(yesterday_count).to be_present
      expect(yesterday_count[1]).to eq(1)
    end
    
    it 'returns an empty hash if no pages exist' do
      allow(Page).to receive(:pluck).and_return([])
      
      expect(Page.visits_by_day).to eq({})
    end
  end
end 