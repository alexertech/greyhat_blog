# frozen_string_literal: true

module DashboardsHelper
  # Calculate traffic quality status based on human percentage
  # @param human_percentage [Float] Percentage of human traffic
  # @return [Hash] Status with alert_class and message
  def traffic_quality_status(human_percentage)
    case human_percentage
    when 80..Float::INFINITY
      { alert_class: 'alert-success', message: 'Excelente - Alto porcentaje de tráfico humano' }
    when 60...80
      { alert_class: 'alert-success', message: 'Bueno - Tráfico mayormente humano' }
    when 40...60
      { alert_class: 'alert-warning', message: 'Regular - Equilibrio entre humanos y bots' }
    else
      { alert_class: 'alert-danger', message: 'Atención - Alto porcentaje de tráfico de bots' }
    end
  end

  # Calculate bounce rate color based on percentage
  # @param bounce_rate [Float] Bounce rate percentage
  # @return [String] Bootstrap color class
  def bounce_rate_color(bounce_rate)
    if bounce_rate > 70
      'danger'
    elsif bounce_rate > 50
      'warning'
    else
      'success'
    end
  end

  # Format session duration for display
  # @param seconds [Integer] Duration in seconds
  # @return [String] Formatted duration
  def format_session_duration(seconds)
    return "#{seconds}s" if seconds <= 60

    minutes = (seconds / 60.0).round(1)
    "#{minutes}m"
  end
end
