import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Only redirect if we're on the device setup page
    if (window.location.pathname === '/device_setup') {
      this.setDateCookie() // Set cookie first
      Turbo.visit('/') // Then redirect
    } else {
      this.setDateCookie() // Still set cookie for other pages
    }
  }

  setDateCookie() {
    const today = new Date()
    const formattedDate = today.toISOString().split('T')[0] // Format: YYYY-MM-DD
    document.cookie = `browser_date=${formattedDate}; path=/; max-age=3600` // Expires in 1 hour
  }
} 