# frozen_string_literal: true

class SiteHealth < ApplicationRecord
  validates :metric_type, presence: true
  validates :value, presence: true
  validates :checked_at, presence: true

  before_create :set_checked_at

  scope :recent, -> { where('checked_at >= ?', 24.hours.ago) }
  scope :by_metric, ->(type) { where(metric_type: type) }

  def self.record_response_time(time_ms)
    create!(
      metric_type: 'response_time',
      value: time_ms,
      checked_at: Time.current,
      metadata: { timestamp: Time.current.to_i }
    )
  end

  def self.record_error(error_type, details = {})
    create!(
      metric_type: 'error',
      value: 1,
      checked_at: Time.current,
      metadata: { error_type: error_type, details: details, timestamp: Time.current.to_i }
    )
  end

  def self.record_uptime_check(status)
    create!(
      metric_type: 'uptime',
      value: status == 'up' ? 1 : 0,
      checked_at: Time.current,
      metadata: { status: status, timestamp: Time.current.to_i }
    )
  end

  def self.average_response_time(hours = 24)
    by_metric('response_time')
      .where('checked_at >= ?', hours.hours.ago)
      .average(:value)
      .to_f
      .round(2)
  end

  def self.uptime_percentage(hours = 24)
    uptime_checks = by_metric('uptime').where('checked_at >= ?', hours.hours.ago)
    return 100.0 if uptime_checks.empty?

    up_count = uptime_checks.where(value: 1).count
    total_count = uptime_checks.count
    (up_count.to_f / total_count * 100).round(2)
  end

  def self.error_count(hours = 24)
    by_metric('error').where('checked_at >= ?', hours.hours.ago).count
  end

  def self.health_status
    avg_response = average_response_time(1) # Last hour
    uptime = uptime_percentage(24)
    errors = error_count(1)

    status = if uptime >= 99 && avg_response < 1000 && errors == 0
               'excellent'
             elsif uptime >= 95 && avg_response < 2000 && errors < 5
               'good'
             elsif uptime >= 90 && avg_response < 5000 && errors < 10
               'warning'
             else
               'critical'
             end

    {
      status: status,
      uptime: uptime,
      avg_response_time: avg_response,
      error_count: errors,
      last_check: maximum(:checked_at)
    }
  end

  def self.traffic_anomaly_detection
    # Detect unusual traffic patterns
    current_hour_visits = Visit.where('viewed_at >= ?', 1.hour.ago).count
    avg_hourly_visits = Visit.where('viewed_at >= ?', 7.days.ago)
                             .group(Arel.sql('EXTRACT(HOUR FROM viewed_at)'))
                             .count
                             .values
                             .sum.to_f / (7 * 24)

    anomaly_threshold = avg_hourly_visits * 3 # 3x normal traffic
    
    {
      current_hour_visits: current_hour_visits,
      average_hourly: avg_hourly_visits.round(1),
      is_anomaly: current_hour_visits > anomaly_threshold,
      threshold: anomaly_threshold.round(1)
    }
  end

  private

  def set_checked_at
    self.checked_at ||= Time.current
  end
end