# frozen_string_literal: true

require 'rails_helper'

# Shared examples for testing Visitable concern
RSpec.shared_examples 'a visitable model' do
  let(:visitable_factory) { described_class.name.underscore.to_sym }

  describe 'associations' do
    it 'has many visits association' do
      visitable = create(visitable_factory)
      expect(visitable).to respond_to(:visits)
      expect(visitable.visits).to be_empty
    end

    it 'destroys visits when destroyed' do
      visitable = create(visitable_factory)
      visit = create(:visit, visitable: visitable)

      expect { visitable.destroy }.to change { Visit.count }.by(-1)
    end
  end

  describe '#recent_visits' do
    let!(:visitable) { create(visitable_factory) }

    context 'with visits in the last 7 days' do
      before do
        create_list(:visit, 3, visitable: visitable, viewed_at: 3.days.ago)
        create_list(:visit, 2, visitable: visitable, viewed_at: 10.days.ago)
      end

      it 'returns count of recent visits' do
        expect(visitable.recent_visits(7)).to eq(3)
      end

      it 'accepts custom days parameter' do
        expect(visitable.recent_visits(15)).to eq(5)
      end
    end

    context 'with no recent visits' do
      before do
        create_list(:visit, 2, visitable: visitable, viewed_at: 10.days.ago)
      end

      it 'returns zero' do
        expect(visitable.recent_visits(7)).to eq(0)
      end
    end
  end

  describe '.visits_by_day' do
    let!(:visitable1) { create(visitable_factory) }
    let!(:visitable2) { create(visitable_factory) }

    context 'with visits on multiple days' do
      before do
        # Visitable 1 visits
        create(:visit, visitable: visitable1, viewed_at: 2.days.ago.beginning_of_day)
        create(:visit, visitable: visitable1, viewed_at: 2.days.ago.beginning_of_day + 2.hours)
        create(:visit, visitable: visitable1, viewed_at: 1.day.ago.beginning_of_day)

        # Visitable 2 visits
        create(:visit, visitable: visitable2, viewed_at: 2.days.ago.beginning_of_day)

        # Old visit (outside 7 day window)
        create(:visit, visitable: visitable1, viewed_at: 10.days.ago)
      end

      it 'groups visits by date' do
        results = described_class.visits_by_day(7)

        expect(results.keys.length).to be >= 2
        expect(results.values.sum).to eq(4) # Should not include the 10-day-old visit
      end

      it 'respects the days parameter' do
        results_7_days = described_class.visits_by_day(7)
        results_15_days = described_class.visits_by_day(15)

        expect(results_15_days.values.sum).to be >= results_7_days.values.sum
      end
    end

    context 'with no visitable records' do
      before do
        described_class.destroy_all
      end

      it 'returns empty hash' do
        expect(described_class.visits_by_day).to eq({})
      end
    end

    context 'with no visits' do
      it 'returns empty hash' do
        expect(described_class.visits_by_day).to eq({})
      end
    end
  end
end

# Test the concern with Post model
RSpec.describe Post, type: :model do
  it_behaves_like 'a visitable model'
end

# Test the concern with Page model
RSpec.describe Page, type: :model do
  it_behaves_like 'a visitable model'
end
