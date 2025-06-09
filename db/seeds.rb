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
  { id: 1, name: 'index' },
  { id: 2, name: 'about' },
  { id: 3, name: 'services' }
]

pages_data.each do |page_data|
  unless Page.exists?(id: page_data[:id])
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
puts "📊 Creating sample analytics data..."
posts_with_tags = Post.published

posts_with_tags.each do |post|
  # Create some sample visits over the last 30 days
  (1..30).each do |days_ago|
    visit_count = rand(1..5) # Random visits per day
    visit_count.times do |i|
      Visit.create!(
        visitable: post,
        ip_address: "192.168.1.#{rand(1..255)}",
        user_agent: [
          "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
          "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36",
          "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36"
        ].sample,
        referer: ["https://google.com", "https://twitter.com", "direct", ""].sample,
        viewed_at: days_ago.days.ago + (i * 2).hours
      )
    end
  end
  
  # Update unique_visits counter
  post.update!(unique_visits: post.visits.select(:ip_address).distinct.count)
end

# Create visits for pages too
Page.all.each do |page|
  (1..30).each do |days_ago|
    visit_count = rand(1..3)
    visit_count.times do |i|
      Visit.create!(
        visitable: page,
        ip_address: "192.168.1.#{rand(1..255)}",
        user_agent: "Mozilla/5.0 (compatible; sample visit)",
        viewed_at: days_ago.days.ago + (i * 3).hours
      )
    end
  end
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