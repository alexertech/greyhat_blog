import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "toggle", "overlay"]

  connect() {
    this.isOpen = false
    this.updateMenuState()
  }

  toggle() {
    this.isOpen = !this.isOpen
    this.updateMenuState()
  }

  close() {
    this.isOpen = false
    this.updateMenuState()
  }

  outsideClick(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }

  updateMenuState() {
    if (this.hasMenuTarget) {
      this.menuTarget.classList.toggle('show', this.isOpen)
    }
    
    if (this.hasToggleTarget) {
      this.toggleTarget.classList.toggle('active', this.isOpen)
      this.toggleTarget.setAttribute('aria-expanded', this.isOpen)
    }
    
    if (this.hasOverlayTarget) {
      this.overlayTarget.classList.toggle('show', this.isOpen)
    }

    // Prevent body scroll when menu is open
    document.body.classList.toggle('menu-open', this.isOpen)

    // Add/remove click listener for outside clicks
    if (this.isOpen) {
      document.addEventListener('click', this.outsideClick.bind(this))
    } else {
      document.removeEventListener('click', this.outsideClick.bind(this))
    }
  }

  disconnect() {
    document.removeEventListener('click', this.outsideClick.bind(this))
    document.body.classList.remove('menu-open')
  }
}