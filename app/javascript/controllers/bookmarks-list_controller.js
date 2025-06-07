import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "emptyState"]

  connect() {
    this.loadBookmarks()
  }

  loadBookmarks() {
    const bookmarks = this.getBookmarks()
    
    if (bookmarks.length === 0) {
      this.showEmptyState()
    } else {
      this.renderBookmarks(bookmarks)
    }
  }

  getBookmarks() {
    const stored = localStorage.getItem('greyhat_bookmarks')
    return stored ? JSON.parse(stored) : []
  }

  removeBookmark(event) {
    const postId = event.target.dataset.postId
    const bookmarks = this.getBookmarks()
    const filteredBookmarks = bookmarks.filter(bookmark => bookmark.id !== postId)
    localStorage.setItem('greyhat_bookmarks', JSON.stringify(filteredBookmarks))
    this.loadBookmarks()
    this.dispatchBookmarkChangedEvent()
  }

  clearAllBookmarks() {
    if (confirm('¿Estás seguro de que quieres eliminar todos los artículos guardados?')) {
      localStorage.removeItem('greyhat_bookmarks')
      this.loadBookmarks()
      this.dispatchBookmarkChangedEvent()
    }
  }

  renderBookmarks(bookmarks) {
    const sortedBookmarks = bookmarks.sort((a, b) => new Date(b.savedAt) - new Date(a.savedAt))
    
    const html = sortedBookmarks.map(bookmark => `
      <div class="card mb-3">
        <div class="card-body">
          <div class="d-flex justify-content-between align-items-start">
            <div class="flex-grow-1">
              <h5 class="card-title">
                <a href="/posts/${bookmark.slug}" class="text-decoration-none">
                  ${bookmark.title}
                </a>
              </h5>
              <small class="text-muted">
                Guardado el ${new Date(bookmark.savedAt).toLocaleDateString('es-ES', {
                  year: 'numeric',
                  month: 'long',
                  day: 'numeric'
                })}
              </small>
            </div>
            <button class="btn btn-outline-danger btn-sm ms-3" 
                    data-action="click->bookmarks-list#removeBookmark"
                    data-post-id="${bookmark.id}">
              <i class="fas fa-trash"></i>
            </button>
          </div>
        </div>
      </div>
    `).join('')

    if (this.hasContainerTarget) {
      this.containerTarget.innerHTML = html
    }
    
    this.hideEmptyState()
  }

  showEmptyState() {
    if (this.hasEmptyStateTarget) {
      this.emptyStateTarget.classList.remove('d-none')
    }
    if (this.hasContainerTarget) {
      this.containerTarget.innerHTML = ''
    }
  }

  hideEmptyState() {
    if (this.hasEmptyStateTarget) {
      this.emptyStateTarget.classList.add('d-none')
    }
  }

  dispatchBookmarkChangedEvent() {
    window.dispatchEvent(new CustomEvent('bookmarkChanged'))
  }
}