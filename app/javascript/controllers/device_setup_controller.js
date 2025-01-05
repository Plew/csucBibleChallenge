import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.log("DeviceSetup controller connected")
    
    // Only redirect if we're on the device setup page
    if (window.location.pathname === '/device_setup') {
      this.setDateCookie() // Set cookie first
      console.log("Redirecting after setting cookie")
      Turbo.visit('/') // Then redirect
    } else {
      this.setDateCookie() // Still set cookie for other pages
    }
  }

  setDateCookie() {
    const today = new Date()
    const formattedDate = today.toISOString().split('T')[0] // Format: YYYY-MM-DD
    document.cookie = `browser_date=${formattedDate}; path=/; max-age=86400` // Expires in 24 hours
    console.log(`Date cookie set to: ${formattedDate}`)
  }
} 