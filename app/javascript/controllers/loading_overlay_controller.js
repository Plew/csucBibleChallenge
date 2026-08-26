import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["overlay"]

  connect() {
    this.showTimer = null
    this.boundShow = this.scheduleShow.bind(this)
    this.boundHide = this.hide.bind(this)

    document.addEventListener("turbo:visit", this.boundShow)
    document.addEventListener("turbo:before-fetch-request", this.boundShow)
    document.addEventListener("turbo:before-fetch-response", this.boundHide)
    document.addEventListener("turbo:submit-end", this.boundHide)
    document.addEventListener("turbo:fetch-request-error", this.boundHide)
    document.addEventListener("turbo:load", this.boundHide)
    document.addEventListener("turbo:render", this.boundHide)
    document.addEventListener("turbo:before-cache", this.boundHide)
  }

  disconnect() {
    document.removeEventListener("turbo:visit", this.boundShow)
    document.removeEventListener("turbo:before-fetch-request", this.boundShow)
    document.removeEventListener("turbo:before-fetch-response", this.boundHide)
    document.removeEventListener("turbo:submit-end", this.boundHide)
    document.removeEventListener("turbo:fetch-request-error", this.boundHide)
    document.removeEventListener("turbo:load", this.boundHide)
    document.removeEventListener("turbo:render", this.boundHide)
    document.removeEventListener("turbo:before-cache", this.boundHide)
    this.clearTimer()
  }

  scheduleShow(event) {
    if (event && event.target && event.target.closest && event.target.closest("turbo-frame")) return
    
    // Do not show full-page overlay for Turbo Stream or partial updates
    if (event && event.detail && event.detail.fetchOptions && event.detail.fetchOptions.headers) {
      const accept = event.detail.fetchOptions.headers["Accept"] || event.detail.fetchOptions.headers["accept"] || ""
      if (typeof accept === "string" && accept.includes("turbo-stream")) return
    }

    this.clearTimer()
    this.showTimer = setTimeout(() => {
      this.overlayTarget.classList.remove("hidden")
    }, 150)
  }

  hide() {
    this.clearTimer()
    this.overlayTarget.classList.add("hidden")
  }

  clearTimer() {
    if (this.showTimer) {
      clearTimeout(this.showTimer)
      this.showTimer = null
    }
  }
}
