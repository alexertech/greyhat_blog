import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "count", "icon"]
  static values = { postId: Number, liked: Boolean }

  connect() {
    this.updateDisplay()
  }

  toggle() {
    const url = `/posts/${this.postIdValue}/like`
    
    fetch(url, {
      method: 'POST',
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      }
    })
    .then(response => response.json())
    .then(data => {
      // Update all like buttons for this post on the page
      this.updateAllLikeButtons(data.liked, data.likes_count)
    })
    .catch(error => {
      console.error('Error:', error)
    })
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