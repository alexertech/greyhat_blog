import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "tagContainer", "suggestions"]
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
      title.textContent = 'Etiquetas sugeridas:'
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
}