# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TagSuggestionService do
  let!(:existing_tag) { create(:tag, name: 'ruby') }
  let!(:rails_tag) { create(:tag, name: 'rails') }
  
  describe '#suggest_tags' do
    context 'with technical content' do
      it 'suggests technology-specific tags' do
        content = 'This tutorial covers Ruby on Rails development with PostgreSQL database'
        service = described_class.new(content, [])
        
        suggestions = service.suggest_tags(5)
        
        expect(suggestions).to include('ruby', 'rails', 'database')
      end

      it 'matches existing tags in database' do
        content = 'Learning Ruby programming language'
        service = described_class.new(content, [])
        
        suggestions = service.suggest_tags(5)
        
        expect(suggestions).to include('ruby')
      end

      it 'suggests JavaScript framework tags' do
        content = 'React components with props and state management using hooks'
        service = described_class.new(content, [])
        
        suggestions = service.suggest_tags(5)
        
        expect(suggestions).to include('react', 'javascript')
      end

      it 'suggests Vue.js related tags' do
        content = 'Vue.js computed properties and v-if directives'
        service = described_class.new(content, [])
        
        suggestions = service.suggest_tags(5)
        
        expect(suggestions).to include('vue')
      end

      it 'suggests database-related tags' do
        content = 'SQL queries and database schema migration'
        service = described_class.new(content, [])
        
        suggestions = service.suggest_tags(5)
        
        expect(suggestions).to include('database')
      end

      it 'suggests security-related tags' do
        content = 'Vulnerability assessment and encryption techniques'
        service = described_class.new(content, [])
        
        suggestions = service.suggest_tags(5)
        
        expect(suggestions).to include('seguridad')
      end
    end

    context 'with psychology and digital wellness content' do
      it 'suggests psychology tags for brain-related content' do
        content = 'El cerebro humano y la psicología detrás del comportamiento digital'
        service = described_class.new(content, [])
        
        suggestions = service.suggest_tags(5)
        
        expect(suggestions).to include('psicología')
      end

      it 'suggests attention-related tags' do
        content = 'Nuestra atención es limitada y requiere concentración y focus'
        service = described_class.new(content, [])
        
        suggestions = service.suggest_tags(5)
        
        expect(suggestions).to include('atención')
      end

      it 'suggests social media tags' do
        content = 'Instagram, TikTok y YouTube dominan las redes sociales actuales'
        service = described_class.new(content, [])
        
        suggestions = service.suggest_tags(5)
        
        expect(suggestions).to include('redes-sociales')
      end

      it 'suggests digital addiction tags' do
        content = 'La adicción digital y el bucle infinito de dopamina en las apps'
        service = described_class.new(content, [])
        
        suggestions = service.suggest_tags(5)
        
        expect(suggestions).to include('adicción-digital')
      end

      it 'suggests digital wellness tags' do
        content = 'Digital detox and mindfulness practices for better mental health'
        service = described_class.new(content, [])
        
        suggestions = service.suggest_tags(5)
        
        expect(suggestions).to include('detox-digital', 'mindfulness', 'salud-mental')
      end

      it 'suggests screen time management tags' do
        content = 'Managing screen time limits and restrictions for better life balance'
        service = described_class.new(content, [])
        
        suggestions = service.suggest_tags(5)
        
        expect(suggestions).to include('tiempo-pantalla', 'equilibrio-vida')
      end

      it 'suggests privacy and surveillance tags' do
        content = 'Data privacy concerns and digital surveillance tracking'
        service = described_class.new(content, [])
        
        suggestions = service.suggest_tags(5)
        
        expect(suggestions).to include('privacidad')
      end
    end

    context 'with content type analysis' do
      it 'suggests tutorial tags for educational content' do
        content = 'Este es un tutorial paso a paso para principiantes'
        service = described_class.new(content, [])
        
        suggestions = service.suggest_tags(5)
        
        expect(suggestions).to include('tutorial', 'principiantes')
      end

      it 'suggests tips and tricks tags' do
        content = 'Useful tips and tricks for better productivity'
        service = described_class.new(content, [])
        
        suggestions = service.suggest_tags(5)
        
        expect(suggestions).to include('consejos', 'productividad')
      end

      it 'suggests advanced content tags' do
        content = 'Advanced techniques for expert developers and professionals'
        service = described_class.new(content, [])
        
        suggestions = service.suggest_tags(5)
        
        expect(suggestions).to include('avanzado')
      end

      it 'suggests analysis and review tags' do
        content = 'Comprehensive analysis and comparison of different approaches'
        service = described_class.new(content, [])
        
        suggestions = service.suggest_tags(5)
        
        expect(suggestions).to include('análisis')
      end
    end

    context 'with existing tags exclusion' do
      it 'excludes already assigned tags from suggestions' do
        content = 'Ruby on Rails tutorial for web development'
        service = described_class.new(content, ['ruby', 'tutorial'])
        
        suggestions = service.suggest_tags(5)
        
        expect(suggestions).not_to include('ruby', 'tutorial')
        expect(suggestions).to include('rails', 'web')
      end

      it 'is case insensitive when excluding existing tags' do
        content = 'Ruby programming tutorial'
        service = described_class.new(content, ['RUBY', 'Tutorial'])
        
        suggestions = service.suggest_tags(5)
        
        expect(suggestions).not_to include('ruby', 'tutorial')
      end
    end

    context 'with limit parameter' do
      it 'respects the limit parameter' do
        content = 'Ruby Rails JavaScript Python HTML CSS React Vue Angular Node.js'
        service = described_class.new(content, [])
        
        suggestions = service.suggest_tags(3)
        
        expect(suggestions.size).to be <= 3
      end

      it 'returns unique suggestions only' do
        content = 'Ruby ruby RUBY programming'
        service = described_class.new(content, [])
        
        suggestions = service.suggest_tags(5)
        
        expect(suggestions.uniq).to eq(suggestions)
      end
    end

    context 'with edge cases' do
      it 'handles empty content gracefully' do
        service = described_class.new('', [])
        
        suggestions = service.suggest_tags(5)
        
        expect(suggestions).to be_an(Array)
        expect(suggestions).to be_empty
      end

      it 'handles nil content gracefully' do
        service = described_class.new(nil, [])
        
        suggestions = service.suggest_tags(5)
        
        expect(suggestions).to be_an(Array)
      end

      it 'handles very short content' do
        service = described_class.new('Hi', [])
        
        suggestions = service.suggest_tags(5)
        
        expect(suggestions).to be_an(Array)
      end

      it 'handles content with special characters' do
        content = 'Ruby & Rails: A guide for @developers! #programming'
        service = described_class.new(content, [])
        
        expect { service.suggest_tags(5) }.not_to raise_error
      end

      it 'handles multilingual content' do
        content = 'Ruby programming y desarrollo web con JavaScript'
        service = described_class.new(content, [])
        
        suggestions = service.suggest_tags(5)
        
        expect(suggestions).to include('ruby', 'javascript', 'web')
      end
    end

    context 'performance considerations' do
      it 'completes suggestions quickly for large content' do
        large_content = 'Ruby ' * 1000 + 'Rails ' * 500 + 'JavaScript ' * 300
        service = described_class.new(large_content, [])
        
        start_time = Time.current
        service.suggest_tags(5)
        end_time = Time.current
        
        expect(end_time - start_time).to be < 1.0 # Should complete in under 1 second
      end

      it 'handles large existing tags list efficiently' do
        large_existing_tags = (1..100).map { |i| "tag#{i}" }
        service = described_class.new('Ruby programming', large_existing_tags)
        
        expect { service.suggest_tags(5) }.not_to raise_error
      end
    end
  end
end