import { Controller } from "@hotwired/stimulus"

// Sticky header with enhanced shadow on scroll
export default class extends Controller {
  connect() {
    this.handleScroll = this.handleScroll.bind(this)
    window.addEventListener("scroll", this.handleScroll, { passive: true })
    this.handleScroll()
  }

  disconnect() {
    window.removeEventListener("scroll", this.handleScroll)
  }

  handleScroll() {
    const scrollThreshold = 10
    const isScrolled = window.scrollY > scrollThreshold

    this.element.classList.toggle("scrolled", isScrolled)
  }
}
