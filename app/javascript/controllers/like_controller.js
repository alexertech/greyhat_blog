import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "count", "icon"]
  static values = { postId: Number, liked: Boolean }

  connect() {
    this.updateDisplay()
  }

  toggle() {
    // Prevent double-clicking
    if (this.buttonTarget.disabled) return
    
    this.buttonTarget.disabled = true
    const url = `/posts/${this.postIdValue}/like`
    
    fetch(url, {
      method: 'POST',
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      }
    })
    .then(response => {
      if (!response.ok) {
        return response.json().then(err => Promise.reject(err))
      }
      return response.json()
    })
    .then(data => {
      // Update all like buttons for this post on the page
      this.updateAllLikeButtons(data.liked, data.likes_count)
    })
    .catch(error => {
      console.error('Like error:', error)
      this.showError(error.error || 'Error al procesar like')
    })
    .finally(() => {
      // Re-enable button after a short delay
      setTimeout(() => {
        this.buttonTarget.disabled = false
      }, 1000)
    })
  }

  showError(message) {
    // Create a temporary error message
    const errorDiv = document.createElement('div')
    errorDiv.className = 'alert alert-warning alert-dismissible fade show position-fixed'
    errorDiv.style.cssText = 'top: 20px; right: 20px; z-index: 1050; max-width: 300px;'
    errorDiv.innerHTML = `
      <i class="fas fa-exclamation-triangle me-2"></i>
      ${message}
      <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    `
    
    document.body.appendChild(errorDiv)
    
    // Auto-remove after 5 seconds
    setTimeout(() => {
      if (errorDiv.parentNode) {
        errorDiv.remove()
      }
    }, 5000)
  }

  updateAllLikeButtons(liked, likesCount) {
    // Find all like controllers for this post
    const allLikeControllers = document.querySelectorAll(`[data-like-post-id-value="${this.postIdValue}"]`)
    
    allLikeControllers.forEach(element => {
      const controller = this.application.getControllerForElementAndIdentifier(element, 'like')
      if (controller) {
        controller.likedValue = liked
        controller.countTarget.textContent = likesCount
        controller.updateDisplay()
      }
    })
  }

  updateDisplay() {
    if (this.likedValue) {
      this.iconTarget.className = "fas fa-heart text-danger"
      this.buttonTarget.classList.add("btn-outline-danger")
      this.buttonTarget.classList.remove("btn-outline-secondary")
    } else {
      this.iconTarget.className = "far fa-heart"
      this.buttonTarget.classList.add("btn-outline-secondary")
      this.buttonTarget.classList.remove("btn-outline-danger")
    }
  }
}