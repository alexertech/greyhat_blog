import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["bookmarksLink"]

  connect() {
    this.updateBookmarksVisibility()
    // Listen for bookmark changes across the site
    window.addEventListener('bookmarkChanged', this.updateBookmarksVisibility.bind(this))
  }

  disconnect() {
    window.removeEventListener('bookmarkChanged', this.updateBookmarksVisibility.bind(this))
  }

  updateBookmarksVisibility() {
    const hasBookmarks = this.hasBookmarks()
    
    this.bookmarksLinkTargets.forEach(target => {
      if (hasBookmarks) {
        target.classList.remove('d-none')
      } else {
        target.classList.add('d-none')
      }
    })
  }

  hasBookmarks() {
    const stored = localStorage.getItem('greyhat_bookmarks')
    const bookmarks = stored ? JSON.parse(stored) : []
    return bookmarks.length > 0
  }
}