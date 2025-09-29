# frozen_string_literal: true

class VisitTrackingService
  def initialize(visitable, request)
    @visitable = visitable
    @request = request
  end

  def track_visit(action_type: 'page_view')
    return unless @visitable

    Visit.transaction do
      # Check for existing visit in last 24 hours
      existing_visit = recent_visit_exists?

      # Increment unique visits counter if no recent visit
      increment_unique_visits unless existing_visit

      # Always record the visit for analytics
      create_visit_record(action_type)
    end
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.warn "Failed to track visit for #{@visitable.class.name} #{@visitable.id}: #{e.message}"
  end

  private

  def recent_visit_exists?
    Visit.where(
      visitable: @visitable,
      ip_address: @request.remote_ip,
      viewed_at: 24.hours.ago..Time.current
    ).exists?
  end

  def increment_unique_visits
    @visitable.increment!(:unique_visits) if @visitable.respond_to?(:unique_visits)
  end

  def create_visit_record(action_type)
    Visit.create!(
      visitable: @visitable,
      ip_address: @request.remote_ip,
      user_agent: @request.user_agent,
      referer: @request.referer,
      action_type: action_type
    )
  end
end