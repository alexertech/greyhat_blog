# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DashboardsHelper, type: :helper do
  describe '#traffic_quality_status' do
    it 'returns excellent status for 80%+' do
      result = helper.traffic_quality_status(85)
      expect(result[:alert_class]).to eq('alert-success')
      expect(result[:message]).to include('Excelente')
    end

    it 'returns good status for 60-79%' do
      result = helper.traffic_quality_status(70)
      expect(result[:alert_class]).to eq('alert-success')
      expect(result[:message]).to include('Bueno')
    end

    it 'returns regular status for 40-59%' do
      result = helper.traffic_quality_status(50)
      expect(result[:alert_class]).to eq('alert-warning')
      expect(result[:message]).to include('Regular')
    end

    it 'returns attention status for below 40%' do
      result = helper.traffic_quality_status(30)
      expect(result[:alert_class]).to eq('alert-danger')
      expect(result[:message]).to include('Atención')
    end
  end

  describe '#bounce_rate_color' do
    it 'returns danger for high bounce rate' do
      expect(helper.bounce_rate_color(75)).to eq('danger')
    end

    it 'returns warning for medium bounce rate' do
      expect(helper.bounce_rate_color(55)).to eq('warning')
    end

    it 'returns success for low bounce rate' do
      expect(helper.bounce_rate_color(30)).to eq('success')
    end
  end

  describe '#format_session_duration' do
    it 'formats seconds for durations under 60s' do
      expect(helper.format_session_duration(45)).to eq('45s')
    end

    it 'formats minutes for durations over 60s' do
      expect(helper.format_session_duration(120)).to eq('2.0m')
    end

    it 'rounds minutes to one decimal' do
      expect(helper.format_session_duration(95)).to eq('1.6m')
    end
  end
end
