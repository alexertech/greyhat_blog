import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["progress", "article"]

  connect() {
    this.updateProgress()
    window.addEventListener('scroll', this.updateProgress.bind(this))
    window.addEventListener('resize', this.updateProgress.bind(this))
  }

  disconnect() {
    window.removeEventListener('scroll', this.updateProgress.bind(this))
    window.removeEventListener('resize', this.updateProgress.bind(this))
  }

  updateProgress() {
    if (!this.hasArticleTarget) return

    const article = this.articleTarget
    const articleTop = article.offsetTop
    const articleHeight = article.offsetHeight
    const windowHeight = window.innerHeight
    const scrollTop = window.pageYOffset

    const articleBottom = articleTop + articleHeight
    const scrollProgress = Math.max(0, Math.min(1, 
      (scrollTop - articleTop + windowHeight) / (articleHeight + windowHeight)
    ))

    const percentage = Math.round(scrollProgress * 100)
    
    if (this.hasProgressTarget) {
      this.progressTarget.style.width = `${percentage}%`
      this.progressTarget.setAttribute('aria-valuenow', percentage)
    }
  }
}