# frozen_string_literal: true

class TagSuggestionService
  def initialize(text, existing_tags = [])
    @text = text.to_s.downcase
    @existing_tags = existing_tags.map(&:downcase)
  end

  def suggest_tags(limit = 5)
    # Combine different suggestion strategies
    suggestions = []
    
    # Strategy 1: Match existing tags in the database
    suggestions.concat(match_existing_tags)
    
    # Strategy 2: Extract keywords from content
    suggestions.concat(extract_keywords)
    
    # Strategy 3: Technology-specific suggestions
    suggestions.concat(technology_suggestions)
    
    # Strategy 4: Content type suggestions
    suggestions.concat(content_type_suggestions)
    
    # Strategy 5: Social and psychology topics
    suggestions.concat(social_psychology_suggestions)
    
    # Strategy 6: Digital wellness and lifestyle
    suggestions.concat(digital_wellness_suggestions)
    
    # Remove duplicates, existing tags, and limit results
    suggestions.uniq
               .reject { |tag| @existing_tags.include?(tag.downcase) }
               .first(limit)
  end

  private

  def match_existing_tags
    return [] if @text.blank?
    
    # Get all existing tags and check if their names appear in the text
    Tag.pluck(:name).select do |tag_name|
      @text.include?(tag_name.downcase)
    end
  end

  def extract_keywords
    return [] if @text.blank?
    
    # Common tech keywords that make good tags
    tech_keywords = {
      'ruby' => ['ruby'],
      'rails' => ['rails', 'ruby on rails'],
      'javascript' => ['javascript', 'js'],
      'react' => ['react', 'reactjs'],
      'vue' => ['vue', 'vuejs'],
      'angular' => ['angular'],
      'node' => ['node', 'nodejs'],
      'python' => ['python'],
      'django' => ['django'],
      'flask' => ['flask'],
      'express' => ['express'],
      'database' => ['database', 'db', 'sql', 'postgresql', 'mysql'],
      'api' => ['api', 'rest', 'graphql'],
      'frontend' => ['frontend', 'front-end'],
      'backend' => ['backend', 'back-end'],
      'fullstack' => ['fullstack', 'full-stack'],
      'web' => ['web development', 'desarrollo web'],
      'seguridad' => ['security', 'seguridad', 'cybersecurity'],
      'testing' => ['test', 'testing', 'rspec', 'jest', 'cypress'],
      'deployment' => ['deploy', 'deployment', 'production'],
      'docker' => ['docker', 'container'],
      'kubernetes' => ['kubernetes', 'k8s'],
      'aws' => ['aws', 'amazon web services'],
      'git' => ['git', 'github', 'gitlab'],
      'css' => ['css', 'sass', 'scss'],
      'html' => ['html', 'html5'],
      'mobile' => ['mobile', 'ios', 'android'],
      'ai' => ['ai', 'artificial intelligence', 'machine learning', 'ml'],
      'tutorial' => ['tutorial', 'guide', 'how to', 'cómo'],
      'tips' => ['tips', 'tricks', 'consejos'],
      'performance' => ['performance', 'optimization', 'speed'],
      'ux' => ['ux', 'user experience', 'ui', 'design'],
      'architecture' => ['architecture', 'pattern', 'mvc'],
      'devops' => ['devops', 'ci/cd', 'automation'],
      'psicología' => ['psicología', 'psychology', 'mental', 'cerebro', 'brain'],
      'atención' => ['atención', 'attention', 'focus', 'concentración'],
      'redes-sociales' => ['instagram', 'tiktok', 'youtube', 'facebook', 'social media'],
      'bienestar' => ['bienestar', 'wellness', 'salud', 'health'],
      'productividad' => ['productividad', 'productivity', 'eficiencia', 'efficiency'],
      'reflexión' => ['reflexión', 'reflection', 'pensamiento', 'thinking'],
      'sociedad' => ['sociedad', 'society', 'cultura', 'culture'],
      'tecnología' => ['tecnología', 'technology', 'digital', 'online']
    }
    
    found_tags = []
    tech_keywords.each do |tag, keywords|
      if keywords.any? { |keyword| @text.include?(keyword) }
        found_tags << tag
      end
    end
    
    found_tags
  end

  def technology_suggestions
    suggestions = []
    
    # Rails-specific patterns
    if @text.match?(/controller|model|view|route|migration|gem|bundle/)
      suggestions << 'rails'
    end
    
    # JavaScript frameworks
    if @text.match?(/component|props|state|hook|useeffect/)
      suggestions << 'react'
    end
    
    if @text.match?(/computed|directive|v-if|v-for/)
      suggestions << 'vue'
    end
    
    # Database patterns
    if @text.match?(/query|table|index|migration|schema/)
      suggestions << 'database'
    end
    
    # Security patterns
    if @text.match?(/vulnerability|attack|encryption|authentication|authorization/)
      suggestions << 'seguridad'
    end
    
    # Performance patterns
    if @text.match?(/optimize|cache|performance|speed|memory/)
      suggestions << 'performance'
    end
    
    suggestions
  end

  def content_type_suggestions
    suggestions = []
    
    # Tutorial indicators
    if @text.match?(/paso|step|tutorial|guía|guide|how to|cómo/)
      suggestions << 'tutorial'
    end
    
    # Tips and tricks
    if @text.match?(/tip|trick|consejo|secreto|hack/)
      suggestions << 'consejos'
    end
    
    # Best practices
    if @text.match?(/best practice|buena práctica|patrón|pattern/)
      suggestions << 'buenas-prácticas'
    end
    
    # Beginner content
    if @text.match?(/beginner|principiante|básico|introducción|introduction/)
      suggestions << 'principiantes'
    end
    
    # Advanced content
    if @text.match?(/advanced|avanzado|expert|professional/)
      suggestions << 'avanzado'
    end
    
    # Review/analysis
    if @text.match?(/review|análisis|comparison|comparación/)
      suggestions << 'análisis'
    end
    
    # News/updates
    if @text.match?(/new|nuevo|update|actualización|release|version/)
      suggestions << 'noticias'
    end
    
    suggestions
  end
  
  def social_psychology_suggestions
    suggestions = []
    
    # Psychology and behavior
    if @text.match?(/psicología|psychology|comportamiento|behavior|cerebro|brain|mente|mind/)
      suggestions << 'psicología'
    end
    
    # Social media and digital behavior
    if @text.match?(/redes sociales|social media|instagram|tiktok|youtube|facebook|twitter/)
      suggestions << 'redes-sociales'
    end
    
    # Attention and focus
    if @text.match?(/atención|attention|concentración|focus|distracción|distraction/)
      suggestions << 'atención'
    end
    
    # Digital addiction and wellness
    if @text.match?(/adicción|addiction|dopamina|dopamine|bucle|scroll|swipe/)
      suggestions << 'adicción-digital'
    end
    
    # User experience and design
    if @text.match?(/usabilidad|usability|interfaz|interface|ux|ui|diseño|design|usuario|user/)
      suggestions << 'experiencia-usuario'
    end
    
    # Algorithms and manipulation
    if @text.match?(/algoritmo|algorithm|manipulación|manipulation|recomendación|recommendation/)
      suggestions << 'algoritmos'
    end
    
    # Time and productivity
    if @text.match?(/tiempo|time|productividad|productivity|procrastinación|procrastination/)
      suggestions << 'productividad'
    end
    
    # Society and culture
    if @text.match?(/sociedad|society|cultura|culture|social|tendencia|trend/)
      suggestions << 'sociedad'
    end
    
    suggestions
  end
  
  def digital_wellness_suggestions
    suggestions = []
    
    # Digital detox and minimalism
    if @text.match?(/detox digital|digital detox|minimalismo|minimalism|desconectar|disconnect/)
      suggestions << 'detox-digital'
    end
    
    # Mental health
    if @text.match?(/salud mental|mental health|bienestar|wellness|estrés|stress|ansiedad|anxiety/)
      suggestions << 'salud-mental'
    end
    
    # Mindfulness and meditation
    if @text.match?(/mindfulness|meditación|meditation|consciencia|awareness|presente|present/)
      suggestions << 'mindfulness'
    end
    
    # Screen time and limits
    if @text.match?(/tiempo de pantalla|screen time|límite|limit|restricción|restriction/)
      suggestions << 'tiempo-pantalla'
    end
    
    # Life balance
    if @text.match?(/equilibrio|balance|vida|life|familia|family|relaciones|relationships/)
      suggestions << 'equilibrio-vida'
    end
    
    # Digital privacy and security
    if @text.match?(/privacidad|privacy|datos|data|vigilancia|surveillance|tracking/)
      suggestions << 'privacidad'
    end
    
    # Technology criticism
    if @text.match?(/crítica|criticism|reflexión|reflection|impacto|impact|consecuencia|consequence/)
      suggestions << 'crítica-tecnológica'
    end
    
    # Habits and self-control
    if @text.match?(/hábito|habit|autocontrol|self-control|disciplina|discipline|voluntad|willpower/)
      suggestions << 'autocontrol'
    end
    
    suggestions
  end
end