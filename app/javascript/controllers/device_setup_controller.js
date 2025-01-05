import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.log("DeviceSetup controller connected")
    this.setDateCookie()
  }

  setDateCookie() {
    const today = new Date()
    const formattedDate = today.toISOString().split('T')[0] // Format: YYYY-MM-DD
    document.cookie = `browser_date=${formattedDate}; path=/; max-age=86400` // Expires in 24 hours
    console.log(`Date cookie set to: ${formattedDate}`)
  }
} 