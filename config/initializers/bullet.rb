# frozen_string_literal: true

if defined?(Bullet)
  Bullet.enable = true
  Bullet.bullet_logger = true
  Bullet.console = true
  Bullet.rails_logger = true
  Bullet.add_footer = true if Rails.env.development?
  
  # Alert types to track
  Bullet.n_plus_one_query_enable = true
  Bullet.unused_eager_loading_enable = true
  Bullet.counter_cache_enable = true
  
  # Skip bullet for specific controllers if needed
  # Bullet.skip_html_injection = false
end