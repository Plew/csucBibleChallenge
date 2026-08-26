import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    switchUrl: String,
    isActive: Boolean
  }

  connect() {
    this.lastTap = 0
  }

  handleTap(event) {
    // If the click/tap is directly on an interactive button, link, form, or input, let it handle itself
    if (event.target.closest("button, a, input, select, textarea, label, form")) {
      return
    }

    const currentTime = new Date().getTime()
    const tapLength = currentTime - this.lastTap

    if (tapLength < 400 && tapLength > 0) {
      event.preventDefault()
      this.performSwitch()
      this.lastTap = 0
    } else {
      this.lastTap = currentTime
    }
  }

  handleDblClick(event) {
    if (event.target.closest("button, a, input, select, textarea, label, form")) {
      return
    }
    event.preventDefault()
    this.performSwitch()
  }

  async performSwitch() {
    // If already active, no need to switch
    if (this.isActiveValue) return
    if (!this.hasSwitchUrlValue || !this.switchUrlValue) return

    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

    try {
      const response = await fetch(this.switchUrlValue, {
        method: "POST",
        headers: {
          "Accept": "text/vnd.turbo-stream.html, text/html, application/xhtml+xml",
          "X-CSRF-Token": csrfToken || "",
          "Content-Type": "application/x-www-form-urlencoded"
        },
        body: new URLSearchParams({
          "_method": "patch",
          "authenticity_token": csrfToken || ""
        })
      })

      if (response.ok) {
        const streamHtml = await response.text()
        if (window.Turbo && typeof window.Turbo.renderStreamMessage === "function") {
          window.Turbo.renderStreamMessage(streamHtml)
        }
      }
    } catch (error) {
      console.error("Error switching active challenge:", error)
    }
  }
}
