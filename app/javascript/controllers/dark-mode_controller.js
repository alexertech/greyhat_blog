import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["toggle", "icon"]

  connect() {
    this.initializeTheme()
    this.updateUI()
  }

  initializeTheme() {
    const savedTheme = localStorage.getItem('theme')
    
    if (savedTheme) {
      this.setTheme(savedTheme)
    } else {
      // Always default to light mode
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
        ? 'fas fa-moon' 
        : 'fas fa-sun'
      this.iconTarget.style.color = currentTheme === 'dark' ? '#fff' : '#333'
    }
    
    if (this.hasToggleTarget) {
      // Update button styling based on theme
      const slider = this.toggleTarget.querySelector('.theme-toggle-slider')
      if (slider) {
        if (currentTheme === 'dark') {
          // Dark mode - slider to the right, dark colors
          slider.style.transform = 'translateX(24px)'
          slider.style.background = 'linear-gradient(45deg, #4a5568, #2d3748)'
          this.toggleTarget.style.background = '#2d3748'
          this.toggleTarget.style.borderColor = '#4a5568'
        } else {
          // Light mode - slider to the left, light colors  
          slider.style.transform = 'translateX(0px)'
          slider.style.background = 'linear-gradient(45deg, #ffd700, #ffed4a)'
          this.toggleTarget.style.background = '#f8f9fa'
          this.toggleTarget.style.borderColor = '#6c757d'
        }
      }
      
      this.toggleTarget.setAttribute('aria-label', 
        currentTheme === 'dark' ? 'Cambiar a modo claro' : 'Cambiar a modo oscuro'
      )
    }
  }
}