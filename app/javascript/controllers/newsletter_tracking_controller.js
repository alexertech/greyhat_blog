import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["link"]

  connect() {
    console.log("Newsletter tracking controller connected")
  }

  trackClick(event) {
    // Track the click asynchronously
    this.sendTrackingData()
    
    // Allow the link to proceed normally
    return true
  }

  async sendTrackingData() {
    try {
      await fetch('/newsletter/track-click', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.getAttribute('content')
        },
        body: JSON.stringify({
          timestamp: new Date().toISOString(),
          page: window.location.pathname
        })
      })
    } catch (error) {
      console.error('Error tracking newsletter click:', error)
    }
  }
}