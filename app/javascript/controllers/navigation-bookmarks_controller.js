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
    
    if (this.hasBookmarksLinkTarget) {
      if (hasBookmarks) {
        this.bookmarksLinkTarget.classList.remove('d-none')
      } else {
        this.bookmarksLinkTarget.classList.add('d-none')
      }
    }
  }

  hasBookmarks() {
    const stored = localStorage.getItem('greyhat_bookmarks')
    const bookmarks = stored ? JSON.parse(stored) : []
    return bookmarks.length > 0
  }
}