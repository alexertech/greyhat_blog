# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PostsHelper, type: :helper do
  describe '#reading_time' do
    let(:post) { create(:post) }

    it 'returns 1 for empty posts' do
      allow(post).to receive_message_chain(:body, :blank?).and_return(true)
      expect(helper.reading_time(post)).to eq(1)
    end

    it 'calculates reading time based on word count' do
      allow(post).to receive_message_chain(:body, :to_plain_text).and_return('word ' * 200)
      expect(helper.reading_time(post)).to eq(1)
    end

    it 'rounds up reading time' do
      allow(post).to receive_message_chain(:body, :to_plain_text).and_return('word ' * 250)
      expect(helper.reading_time(post)).to eq(2)
    end

    it 'returns minimum of 1 minute' do
      allow(post).to receive_message_chain(:body, :to_plain_text).and_return('few words')
      expect(helper.reading_time(post)).to eq(1)
    end
  end

  describe '#reading_time_text' do
    let(:post) { create(:post) }

    it 'formats reading time with text' do
      allow(helper).to receive(:reading_time).with(post).and_return(5)
      expect(helper.reading_time_text(post)).to eq('5 min de lectura')
    end
  end
end
