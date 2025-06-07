import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["toggle", "icon"]

  connect() {
    this.initializeTheme()
    this.updateUI()
  }

  initializeTheme() {
    const savedTheme = localStorage.getItem('theme')
    const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches
    
    if (savedTheme) {
      this.setTheme(savedTheme)
    } else if (prefersDark) {
      this.setTheme('dark')
    } else {
      this.setTheme('light')
    }
  }

  toggle() {
    const currentTheme = document.documentElement.getAttribute('data-theme')
    const newTheme = currentTheme === 'dark' ? 'light' : 'dark'
    
    this.setTheme(newTheme)
    this.updateUI()
  }

  setTheme(theme) {
    document.documentElement.setAttribute('data-theme', theme)
    localStorage.setItem('theme', theme)
  }

  updateUI() {
    const currentTheme = document.documentElement.getAttribute('data-theme')
    
    if (this.hasIconTarget) {
      this.iconTarget.className = currentTheme === 'dark' 
        ? 'fas fa-sun' 
        : 'fas fa-moon'
    }
    
    if (this.hasToggleTarget) {
      this.toggleTarget.setAttribute('aria-label', 
        currentTheme === 'dark' ? 'Cambiar a modo claro' : 'Cambiar a modo oscuro'
      )
    }
  }
}