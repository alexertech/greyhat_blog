# frozen_string_literal: true

class ConversionAnalyticsService
  def initialize(params = {})
    @params = params
  end

  def conversion_funnel
    # Simple conversion funnel: Home → Post → Contact
    total_visitors = Visit.distinct.count(:ip_address)
    return {} if total_visitors.zero?

    # Visitors who viewed home page
    home_visitors = Visit.joins('JOIN pages ON visits.visitable_id = pages.id')
                         .where("visits.visitable_type = 'Page' AND pages.name = 'index'")
                         .distinct
                         .count(:ip_address)

    # Visitors who viewed any post
    post_visitors = Visit.where(visitable_type: 'Post')
                         .distinct
                         .count(:ip_address)

    # Visitors who contacted
    contact_visitors = Visit.joins('JOIN pages ON visits.visitable_id = pages.id')
                            .where("visits.visitable_type = 'Page' AND pages.name = 'contact'")
                            .distinct
                            .count(:ip_address)

    {
      'Total Visitantes' => total_visitors,
      'Vieron Inicio' => home_visitors,
      'Leyeron Artículos' => post_visitors,
      'Visitaron Contacto' => contact_visitors,
      'Conversión a Artículos' => total_visitors.positive? ? "#{((post_visitors.to_f / total_visitors) * 100).round(1)}%" : '0%',
      'Conversión a Contacto' => total_visitors.positive? ? "#{((contact_visitors.to_f / total_visitors) * 100).round(1)}%" : '0%'
    }
  end
end