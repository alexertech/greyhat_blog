import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "tagContainer", "suggestions", "aiSuggestions", "analyzeButton"]
  static values = { 
    existingTags: Array,
    currentTags: Array
  }

  connect() {
    this.tags = this.currentTagsValue || []
    this.updateTagDisplay()
    this.loadExistingTags()
  }

  loadExistingTags() {
    // Fetch existing tags from the server
    fetch('/tags')
      .then(response => response.json())
      .then(tags => {
        this.existingTagsValue = tags
        this.updateSuggestions()
      })
      .catch(error => {
        console.log('Could not load existing tags:', error)
        // Fallback to common tags
        this.existingTagsValue = [
          'ruby', 'rails', 'javascript', 'tecnología', 'seguridad', 
          'desarrollo', 'web', 'programación', 'tutorial', 'consejos'
        ]
        this.updateSuggestions()
      })
  }

  addTag(event) {
    const tagName = event.target.dataset.tagName || event.target.textContent.trim()
    if (tagName && !this.tags.includes(tagName)) {
      this.tags.push(tagName)
      this.updateTagDisplay()
      this.updateInput()
      this.updateSuggestions()
    }
  }

  removeTag(event) {
    const tagName = event.target.closest('.tag-item').dataset.tagName
    this.tags = this.tags.filter(tag => tag !== tagName)
    this.updateTagDisplay()
    this.updateInput()
    this.updateSuggestions()
  }

  handleInput(event) {
    const value = event.target.value
    const tags = value.split(',').map(tag => tag.trim()).filter(tag => tag !== '')
    this.tags = tags
    this.updateTagDisplay()
    this.updateSuggestions()
  }

  handleKeydown(event) {
    if (event.key === 'Enter') {
      event.preventDefault()
      const currentValue = this.inputTarget.value.trim()
      if (currentValue && !this.tags.includes(currentValue)) {
        this.tags.push(currentValue)
        this.inputTarget.value = this.tags.join(', ')
        this.updateTagDisplay()
        this.updateSuggestions()
      }
    }
  }

  updateTagDisplay() {
    if (!this.hasTagContainerTarget) return
    
    this.tagContainerTarget.innerHTML = ''
    this.tags.forEach(tag => {
      const tagElement = document.createElement('span')
      tagElement.className = 'tag-item badge bg-primary me-1 mb-1 d-inline-flex align-items-center'
      tagElement.dataset.tagName = tag
      tagElement.innerHTML = `
        <i class="fas fa-tag me-1"></i>
        ${tag}
        <button type="button" class="btn-close btn-close-white ms-1" 
                data-action="click->tag-manager#removeTag" 
                aria-label="Remove tag"
                style="font-size: 0.6em;"></button>
      `
      this.tagContainerTarget.appendChild(tagElement)
    })
  }

  updateInput() {
    this.inputTarget.value = this.tags.join(', ')
  }

  updateSuggestions() {
    if (!this.hasSuggestionsTarget) return
    
    const availableTags = this.existingTagsValue.filter(tag => 
      !this.tags.includes(tag)
    ).slice(0, 10)
    
    this.suggestionsTarget.innerHTML = ''
    if (availableTags.length > 0) {
      const title = document.createElement('small')
      title.className = 'text-muted d-block mb-2'
      title.textContent = 'Etiquetas populares:'
      this.suggestionsTarget.appendChild(title)
      
      availableTags.forEach(tag => {
        const suggestion = document.createElement('button')
        suggestion.type = 'button'
        suggestion.className = 'btn btn-outline-secondary btn-sm me-1 mb-1'
        suggestion.dataset.tagName = tag
        suggestion.innerHTML = `<i class="fas fa-plus me-1"></i>${tag}`
        suggestion.addEventListener('click', (e) => this.addTag(e))
        this.suggestionsTarget.appendChild(suggestion)
      })
    }
  }

  async analyzeContent() {
    if (!this.hasAnalyzeButtonTarget) return
    
    // Get content from Trix editor or regular textarea
    const contentElement = document.querySelector('trix-editor') || 
                          document.querySelector('#post_body') ||
                          document.querySelector('textarea[name*="body"]')
    
    if (!contentElement) {
      alert('No se pudo encontrar el contenido del post para analizar')
      return
    }
    
    let content = ''
    if (contentElement.tagName === 'TRIX-EDITOR') {
      content = contentElement.value || contentElement.textContent
    } else {
      content = contentElement.value
    }
    
    if (!content || content.trim().length < 50) {
      alert('Escribe al menos 50 caracteres en el contenido del post para obtener sugerencias inteligentes')
      return
    }
    
    this.analyzeButtonTarget.disabled = true
    this.analyzeButtonTarget.innerHTML = '<i class="fas fa-spinner fa-spin me-1"></i>Analizando...'
    
    try {
      const response = await fetch('/tags/suggest', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
        },
        body: JSON.stringify({
          content: content,
          existing_tags: this.tags.join(',')
        })
      })
      
      if (response.ok) {
        const data = await response.json()
        this.displayAISuggestions(data.suggestions)
      } else {
        throw new Error('Error al analizar el contenido')
      }
    } catch (error) {
      console.error('Error:', error)
      alert('Error al analizar el contenido. Inténtalo de nuevo.')
    } finally {
      this.analyzeButtonTarget.disabled = false
      this.analyzeButtonTarget.innerHTML = '<i class="fas fa-magic me-1"></i>Analizar contenido'
    }
  }
  
  displayAISuggestions(suggestions) {
    if (!this.hasAiSuggestionsTarget || !suggestions || suggestions.length === 0) {
      if (this.hasAiSuggestionsTarget) {
        this.aiSuggestionsTarget.innerHTML = '<small class="text-muted">No se encontraron sugerencias relevantes</small>'
      }
      return
    }
    
    this.aiSuggestionsTarget.innerHTML = ''
    
    const title = document.createElement('small')
    title.className = 'text-muted d-block mb-2'
    title.innerHTML = '<i class="fas fa-magic me-1"></i>Sugerencias inteligentes:'
    this.aiSuggestionsTarget.appendChild(title)
    
    suggestions.forEach(tag => {
      const suggestion = document.createElement('button')
      suggestion.type = 'button'
      suggestion.className = 'btn btn-outline-primary btn-sm me-1 mb-1'
      suggestion.dataset.tagName = tag
      suggestion.innerHTML = `<i class="fas fa-sparkles me-1"></i>${tag}`
      suggestion.addEventListener('click', (e) => {
        this.addTag(e)
        // Remove the suggestion after adding it
        suggestion.remove()
      })
      this.aiSuggestionsTarget.appendChild(suggestion)
    })
  }
}