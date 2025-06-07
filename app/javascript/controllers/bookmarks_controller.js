import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "icon", "text"]
  static values = { postId: String, postTitle: String, postSlug: String }

  connect() {
    this.updateBookmarkState()
  }

  toggle() {
    if (this.isBookmarked()) {
      this.removeBookmark()
    } else {
      this.addBookmark()
    }
    this.updateBookmarkState()
  }

  isBookmarked() {
    const bookmarks = this.getBookmarks()
    return bookmarks.some(bookmark => bookmark.id === this.postIdValue)
  }

  addBookmark() {
    const bookmarks = this.getBookmarks()
    const newBookmark = {
      id: this.postIdValue,
      title: this.postTitleValue,
      slug: this.postSlugValue,
      savedAt: new Date().toISOString()
    }
    bookmarks.push(newBookmark)
    this.saveBookmarks(bookmarks)
    this.dispatchBookmarkChangedEvent()
  }

  removeBookmark() {
    const bookmarks = this.getBookmarks()
    const filteredBookmarks = bookmarks.filter(bookmark => bookmark.id !== this.postIdValue)
    this.saveBookmarks(filteredBookmarks)
    this.dispatchBookmarkChangedEvent()
  }

  getBookmarks() {
    const stored = localStorage.getItem('greyhat_bookmarks')
    return stored ? JSON.parse(stored) : []
  }

  saveBookmarks(bookmarks) {
    localStorage.setItem('greyhat_bookmarks', JSON.stringify(bookmarks))
  }

  updateBookmarkState() {
    const isBookmarked = this.isBookmarked()
    
    if (this.hasIconTarget) {
      this.iconTarget.className = isBookmarked 
        ? "fas fa-bookmark text-primary" 
        : "far fa-bookmark text-muted"
    }
    
    if (this.hasTextTarget) {
      this.textTarget.textContent = isBookmarked ? "Guardado" : "Guardar"
    }
    
    if (this.hasButtonTarget) {
      this.buttonTarget.classList.toggle('btn-primary', isBookmarked)
      this.buttonTarget.classList.toggle('btn-outline-secondary', !isBookmarked)
    }
  }

  dispatchBookmarkChangedEvent() {
    window.dispatchEvent(new CustomEvent('bookmarkChanged'))
  }
}