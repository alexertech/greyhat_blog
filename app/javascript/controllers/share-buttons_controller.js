import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { 
    url: String, 
    title: String, 
    description: String 
  }

  shareTwitter() {
    const text = `${this.titleValue} - ${this.descriptionValue}`
    const url = `https://twitter.com/intent/tweet?text=${encodeURIComponent(text)}&url=${encodeURIComponent(this.urlValue)}`
    this.openPopup(url)
  }

  shareLinkedIn() {
    const params = new URLSearchParams({
      url: this.urlValue,
      title: this.titleValue,
      summary: this.descriptionValue,
      source: 'Greyhat'
    })
    const url = `https://www.linkedin.com/sharing/share-offsite/?${params.toString()}`
    this.openPopup(url)
  }

  shareFacebook() {
    const params = new URLSearchParams({
      u: this.urlValue,
      quote: `${this.titleValue} - ${this.descriptionValue}`
    })
    const url = `https://www.facebook.com/sharer/sharer.php?${params.toString()}`
    this.openPopup(url)
  }

  shareWhatsApp() {
    const text = `${this.titleValue} - ${this.urlValue}`
    const url = `https://wa.me/?text=${encodeURIComponent(text)}`
    this.openPopup(url)
  }

  copyLink() {
    navigator.clipboard.writeText(this.urlValue).then(() => {
      this.showCopyFeedback()
    }).catch(() => {
      // Fallback for older browsers
      const textArea = document.createElement('textarea')
      textArea.value = this.urlValue
      document.body.appendChild(textArea)
      textArea.select()
      document.execCommand('copy')
      document.body.removeChild(textArea)
      this.showCopyFeedback()
    })
  }

  openPopup(url) {
    const width = 600
    const height = 400
    const left = (window.innerWidth - width) / 2
    const top = (window.innerHeight - height) / 2
    
    window.open(
      url,
      'sharePopup',
      `width=${width},height=${height},left=${left},top=${top},resizable=yes,scrollbars=yes`
    )
  }

  showCopyFeedback() {
    const button = this.element.querySelector('[data-action*="copyLink"]')
    if (button) {
      const originalText = button.innerHTML
      button.innerHTML = '<i class="fas fa-check"></i> ¡Copiado!'
      button.classList.add('btn-success')
      button.classList.remove('btn-outline-secondary')
      
      setTimeout(() => {
        button.innerHTML = originalText
        button.classList.remove('btn-success')
        button.classList.add('btn-outline-secondary')
      }, 2000)
    }
  }
}