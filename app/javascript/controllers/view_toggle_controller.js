import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="view-toggle"
export default class extends Controller {
  static targets = ["button", "view"]
  static values = {
    default: { type: String, default: "grid" },
    storageKey: { type: String, default: "postsView" }
  }

  connect() {
    // Restore saved view preference from localStorage
    const savedView = localStorage.getItem(this.storageKeyValue)
    if (savedView) {
      this.switchTo(savedView)
    } else {
      this.switchTo(this.defaultValue)
    }
  }

  toggle(event) {
    const viewType = event.currentTarget.dataset.view
    this.switchTo(viewType)

    // Save preference to localStorage
    localStorage.setItem(this.storageKeyValue, viewType)
  }

  switchTo(viewType) {
    // Update button states
    this.buttonTargets.forEach(button => {
      if (button.dataset.view === viewType) {
        button.classList.add('active')
      } else {
        button.classList.remove('active')
      }
    })

    // Update view visibility
    this.viewTargets.forEach(view => {
      if (view.dataset.view === viewType) {
        view.classList.remove('d-none')
      } else {
        view.classList.add('d-none')
      }
    })
  }
}
