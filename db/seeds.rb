# frozen_string_literal: true

# Greyhat Blog Engine - Database Seeds
# This file contains sample data to get your blog up and running quickly
# Run with: rails db:seed

puts "🌱 Seeding Greyhat Blog Engine..."

# Create admin user
puts "👤 Creating admin user..."
unless User.exists?(email: 'admin@example.com')
  User.create!(
    email: 'admin@example.com',
    password: 'password123456',
    password_confirmation: 'password123456'
  )
  puts "   ✅ Admin user created: admin@example.com / password123456"
else
  puts "   ⚠️  Admin user already exists"
end

# Create essential pages
puts "📄 Creating essential pages..."
pages_data = [
  { name: 'index' },
  { name: 'about' },
  { name: 'services' },
  { name: 'newsletter' },
  { name: 'contact' }
]

pages_data.each do |page_data|
  unless Page.exists?(name: page_data[:name])
    Page.create!(page_data)
    puts "   ✅ Created page: #{page_data[:name]}"
  else
    puts "   ⚠️  Page already exists: #{page_data[:name]}"
  end
end

# Create sample tags
puts "🏷️  Creating sample tags..."
sample_tags = [
  'ruby', 'rails', 'javascript', 'tecnología', 'seguridad',
  'desarrollo', 'web', 'programación', 'tutorial', 'consejos',
  'productividad', 'software', 'backend', 'frontend', 'fullstack'
]

sample_tags.each do |tag_name|
  unless Tag.exists?(name: tag_name)
    Tag.create!(name: tag_name)
    puts "   ✅ Created tag: #{tag_name}"
  end
end

# Create sample blog posts
puts "📝 Creating sample blog posts..."

sample_posts = [
  {
    title: "Bienvenido a Greyhat Blog Engine",
    body: '<div><h2>¡Bienvenido a tu nuevo blog!</h2><p>Este es tu primer artículo de ejemplo. Greyhat Blog Engine te proporciona todas las herramientas que necesitas para crear contenido excepcional.</p><h3>Características principales:</h3><ul><li><strong>Editor rico:</strong> Escribe con formato, imágenes y enlaces</li><li><strong>Sistema de etiquetas:</strong> Organiza tu contenido eficientemente</li><li><strong>Análisis avanzado:</strong> Conoce a tu audiencia</li><li><strong>Modo oscuro:</strong> Experiencia visual mejorada</li><li><strong>Responsive:</strong> Perfecto en cualquier dispositivo</li></ul><p>¡Comienza a escribir y comparte tu conocimiento con el mundo!</p></div>',
    tags: ['bienvenida', 'tutorial', 'características'],
    draft: false
  },
  {
    title: "Guía de Desarrollo Web Moderno",
    body: '<div><h2>El paisaje actual del desarrollo web</h2><p>El desarrollo web ha evolucionado dramáticamente en los últimos años. En esta guía, exploraremos las tecnologías y prácticas que definen el desarrollo moderno.</p><h3>Tecnologías Frontend</h3><p>El frontend moderno se caracteriza por frameworks reactivos, herramientas de construcción avanzadas y un enfoque en la experiencia del usuario.</p><h3>Backend robusto</h3><p>Ruby on Rails sigue siendo una excelente opción para desarrollar aplicaciones web robustas y escalables, especialmente cuando se combina con PostgreSQL.</p><blockquote><p>"La simplicidad es la máxima sofisticación" - Leonardo da Vinci</p></blockquote><p>Esta filosofía aplica perfectamente al desarrollo web moderno.</p></div>',
    tags: ['desarrollo', 'web', 'frontend', 'backend', 'rails'],
    draft: false
  },
  {
    title: "Seguridad en Aplicaciones Web: Mejores Prácticas",
    body: '<div><h2>Fundamentos de seguridad web</h2><p>La seguridad debe ser una prioridad desde el primer día de desarrollo. En este artículo, cubrimos las prácticas esenciales para mantener tu aplicación segura.</p><h3>Principales vulnerabilidades</h3><ul><li><strong>XSS (Cross-Site Scripting):</strong> Sanitización de entrada y escape de salida</li><li><strong>SQL Injection:</strong> Uso de consultas preparadas</li><li><strong>CSRF:</strong> Tokens de protección anti-falsificación</li><li><strong>Autenticación:</strong> Implementación robusta y segura</li></ul><h3>Rails Security</h3><p>Ruby on Rails incluye muchas protecciones de seguridad por defecto, pero es importante entender cómo funcionan y cómo implementar capas adicionales de seguridad.</p><p><strong>Recuerda:</strong> La seguridad es un proceso continuo, no un destino.</p></div>',
    tags: ['seguridad', 'web', 'rails', 'desarrollo', 'buenas-prácticas'],
    draft: false
  },
  {
    title: "Draft: Próximas Características del Blog",
    body: '<div><h2>Características en desarrollo</h2><p>Este es un artículo en borrador que muestra las próximas características que se añadirán al blog:</p><ul><li>Sistema de newsletters</li><li>Comentarios mejorados</li><li>Integración con redes sociales</li><li>API RESTful</li></ul><p><em>Nota: Este artículo no es visible para visitantes públicos.</em></p></div>',
    tags: ['desarrollo', 'características', 'roadmap'],
    draft: true
  }
]

sample_posts.each_with_index do |post_data, index|
  unless Post.exists?(title: post_data[:title])
    post = Post.new(
      title: post_data[:title],
      draft: post_data[:draft],
      slug: post_data[:title].parameterize
    )
    
    # Set the ActionText body content
    post.body = post_data[:body]
    
    # Try to attach sample image if it exists
    image_path = Rails.root.join('app', 'assets', 'images', 'new_main.jpg')
    if File.exist?(image_path)
      post.image.attach(
        io: File.open(image_path),
        filename: "sample_#{index + 1}.jpg",
        content_type: 'image/jpeg'
      )
    end
    
    if post.save
      # Assign tags after saving
      tag_list = post_data[:tags]
      tag_list.each do |tag_name|
        tag = Tag.find_or_create_by(name: tag_name.downcase)
        post.tags << tag unless post.tags.include?(tag)
      end
      puts "   ✅ Created post: #{post.title}"
    else
      puts "   ❌ Failed to create post: #{post.title}"
      puts "   Errors: #{post.errors.full_messages.join(', ')}"
      puts "   Post body valid: #{post.body.present?}"
      puts "   Post body class: #{post.body.class}"
    end
  else
    puts "   ⚠️  Post already exists: #{post_data[:title]}"
  end
end

# Create sample comments (approved)
puts "💬 Creating sample comments..."
published_posts = Post.published.limit(2)

sample_comments = [
  {
    username: "María García",
    email: "maria@example.com",
    body: "¡Excelente artículo! Muy útil para comenzar.",
    approved: true
  },
  {
    username: "Carlos López",
    email: "carlos@example.com", 
    body: "Gracias por compartir esta información tan valiosa.",
    approved: true
  },
  {
    username: "Ana Rodríguez",
    email: "ana@example.com",
    body: "Me gustaría ver más contenido sobre este tema.",
    approved: true
  }
]

published_posts.each do |post|
  sample_comments.each do |comment_data|
    unless Comment.exists?(post: post, email: comment_data[:email])
      Comment.create!(
        post: post,
        username: comment_data[:username],
        email: comment_data[:email],
        body: comment_data[:body],
        approved: comment_data[:approved]
      )
      puts "   ✅ Created comment for: #{post.title}"
    end
  end
end

# Create sample visits for analytics
puts "📊 Creating realistic analytics data..."
posts_with_tags = Post.published

# Define realistic referrers and user agents
referrers = [
  'https://google.com/search?q=ruby+programming',
  'https://google.com/search?q=rails+tutorial',
  'https://linkedin.com/feed',
  'https://twitter.com/greyhat_dev',
  'https://substack.com/newsletter',
  'https://dev.to/popular',
  'https://github.com/explore',
  nil, # Direct visits
  ''   # Direct visits
]

user_agents = [
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
  'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
  'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:89.0) Gecko/20100101 Firefox/89.0',
  'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.1.1 Safari/605.1.15',
  'Mozilla/5.0 (iPhone; CPU iPhone OS 14_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Mobile/15E148 Safari/604.1',
  'Mozilla/5.0 (Android 11; Mobile; rv:89.0) Gecko/89.0 Firefox/89.0',
  'Googlebot/2.1 (+http://www.google.com/bot.html)',
  'facebookexternalhit/1.1 (+http://www.facebook.com/externalhit_uatext.php)',
  'LinkedInBot/1.0 (compatible; Mozilla/5.0; +https://www.linkedin.com/)'
]

# Create varied visits for posts
posts_with_tags.each_with_index do |post, index|
  base_popularity = [50, 30, 20][index] || 10 # First post gets more visits
  
  (1..30).each do |days_ago|
    # Weekend factor (more visits on weekends)
    day_of_week = (Date.current - days_ago.days).wday
    weekend_factor = [6, 0].include?(day_of_week) ? 1.5 : 1.0
    
    # Recent posts get more visits
    recency_factor = days_ago <= 7 ? 1.5 : 1.0
    
    daily_visits = (rand(1..base_popularity) * weekend_factor * recency_factor).round
    
    daily_visits.times do |i|
      # Vary the time throughout the day
      hour_offset = rand(0..23)
      minute_offset = rand(0..59)
      
      Visit.create!(
        visitable: post,
        ip_address: "#{rand(1..255)}.#{rand(1..255)}.#{rand(1..255)}.#{rand(1..255)}",
        user_agent: user_agents.sample,
        referer: referrers.sample,
        viewed_at: days_ago.days.ago + hour_offset.hours + minute_offset.minutes,
        action_type: 'page_view'
      )
    end
  end
  
  # Update unique_visits counter
  post.update!(unique_visits: post.visits.select(:ip_address).distinct.count)
end

# Create visits for pages with realistic patterns
page_visit_patterns = {
  'index' => 40,      # Homepage gets most visits
  'about' => 15,      # About page moderate visits  
  'newsletter' => 25, # Newsletter page good visits
  'services' => 10,   # Services moderate visits
  'contact' => 8      # Contact least visits
}

Page.all.each do |page|
  base_visits = page_visit_patterns[page.name] || 5
  
  (1..30).each do |days_ago|
    daily_visits = rand(1..base_visits)
    
    daily_visits.times do |i|
      hour_offset = rand(0..23)
      minute_offset = rand(0..59)
      
      Visit.create!(
        visitable: page,
        ip_address: "#{rand(1..255)}.#{rand(1..255)}.#{rand(1..255)}.#{rand(1..255)}",
        user_agent: user_agents.sample,
        referer: referrers.sample,
        viewed_at: days_ago.days.ago + hour_offset.hours + minute_offset.minutes,
        action_type: 'page_view'
      )
    end
  end
end

# Create newsletter clicks
newsletter_page = Page.find_by(name: 'newsletter')
if newsletter_page
  puts "📧 Creating newsletter conversion data..."
  
  # Create newsletter clicks over the last 30 days
  (1..30).each do |days_ago|
    newsletter_clicks = rand(0..5) # 0-5 newsletter clicks per day
    
    newsletter_clicks.times do |i|
      hour_offset = rand(0..23)
      minute_offset = rand(0..59)
      
      Visit.create!(
        visitable: newsletter_page,
        ip_address: "#{rand(1..255)}.#{rand(1..255)}.#{rand(1..255)}.#{rand(1..255)}",
        user_agent: user_agents.sample,
        referer: ["https://greyhat.cl/articulos", "https://greyhat.cl/index"].sample,
        viewed_at: days_ago.days.ago + hour_offset.hours + minute_offset.minutes,
        action_type: 'newsletter_click'
      )
    end
  end
end

# Create sample contacts
puts "📞 Creating sample contacts..."
(1..10).each do |i|
  days_ago = rand(1..30)
  
  Contact.create!(
    name: ["María García", "Carlos López", "Ana Rodríguez", "Luis Martín", "Elena Vega"].sample + " #{i}",
    email: "usuario#{i}@example.com", 
    message: "Hola, me interesa conocer más sobre sus servicios de desarrollo web.",
    created_at: days_ago.days.ago
  )
end

puts "📈 Sample analytics data created for the last 30 days"

puts ""
puts "🎉 Seeding completed successfully!"
puts ""
puts "📋 Summary:"
puts "   • Admin user: admin@example.com / password123456"
puts "   • Sample posts: #{Post.count} total (#{Post.published.count} published, #{Post.drafts.count} drafts)"
puts "   • Tags: #{Tag.count} available"
puts "   • Comments: #{Comment.count} total (#{Comment.approved.count} approved)"
puts "   • Analytics: #{Visit.count} sample visits"
puts ""
puts "🚀 Your blog is ready! Start the server with: rails server"
puts "   • Public site: http://localhost:3000"
puts "   • Admin dashboard: http://localhost:3000/dashboard"
puts ""