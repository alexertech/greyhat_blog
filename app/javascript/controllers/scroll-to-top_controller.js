import { Controller } from "@hotwired/stimulus"

// Scroll to top floating button
export default class extends Controller {
  connect() {
    this.checkVisibility = this.checkVisibility.bind(this)
    window.addEventListener("scroll", this.checkVisibility, { passive: true })
    this.checkVisibility()
  }

  disconnect() {
    window.removeEventListener("scroll", this.checkVisibility)
  }

  checkVisibility() {
    const scrollThreshold = 300
    const isVisible = window.scrollY > scrollThreshold

    this.element.classList.toggle("visible", isVisible)
  }

  scroll() {
    window.scrollTo({
      top: 0,
      behavior: "smooth"
    })
  }
}
