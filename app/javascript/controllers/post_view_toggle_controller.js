import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.initializeViewToggle()
    this.restoreSavedView()
  }

  initializeViewToggle() {
    const viewButtons = document.querySelectorAll('.view-toggle-btn')
    const postsViews = document.querySelectorAll('.posts-view')
    
    viewButtons.forEach(button => {
      button.addEventListener('click', (e) => {
        const view = button.dataset.view
        
        // Update button states
        viewButtons.forEach(btn => {
          if (btn === button) {
            btn.classList.remove('text-gray-700', 'bg-white', 'border-gray-300')
            btn.classList.add('text-primary-700', 'bg-primary-50', 'border-primary-300')
          } else {
            btn.classList.remove('text-primary-700', 'bg-primary-50', 'border-primary-300')
            btn.classList.add('text-gray-700', 'bg-white', 'border-gray-300')
          }
        })
        
        // Update view visibility
        postsViews.forEach(viewEl => {
          if (viewEl.dataset.view === view) {
            viewEl.classList.remove('hidden')
          } else {
            viewEl.classList.add('hidden')
          }
        })
        
        // Save preference
        localStorage.setItem('postsView', view)
      })
    })
  }

  restoreSavedView() {
    const savedView = localStorage.getItem('postsView')
    if (savedView) {
      const savedButton = document.querySelector(`[data-view="${savedView}"]`)
      if (savedButton) {
        savedButton.click()
      }
    }
  }
}