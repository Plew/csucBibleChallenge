import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "currentFlag"]

  connect() {
    // Load the saved language preference from cookie
    const savedLanguage = this.getCookie('locale') || 'en'
    this.setLanguage(savedLanguage, false)
  }

  toggleMenu() {
    this.menuTarget.classList.toggle('hidden')
  }

  closeMenu(event) {
    if (!this.element.contains(event.target)) {
      this.menuTarget.classList.add('hidden')
    }
  }

  selectLanguage(event) {
    const language = event.currentTarget.dataset.language
    this.setLanguage(language, true)
    this.menuTarget.classList.add('hidden')
  }

  setLanguage(language, saveCookie) {
    // Update the flag display
    const flags = {
      'en': '🇺🇸',
      'de': '🇩🇪'
    }
    this.currentFlagTarget.textContent = flags[language]

    // Save to cookie and notify server if needed
    if (saveCookie) {
      this.setCookie('locale', language, 365)
      // Make request to server to set locale in Rails session
      fetch(`/language?locale=${language}`, {
        method: 'PATCH',
        headers: {
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content,
          'Accept': 'application/json'
        }
      }).then(() => {
        // Reload the page to apply new locale
        window.location.reload()
      })
    }
  }

  getCookie(name) {
    const value = `; ${document.cookie}`
    const parts = value.split(`; ${name}=`)
    if (parts.length === 2) return parts.pop().split(';').shift()
  }

  setCookie(name, value, days) {
    const date = new Date()
    date.setTime(date.getTime() + (days * 24 * 60 * 60 * 1000))
    const expires = `expires=${date.toUTCString()}`
    document.cookie = `${name}=${value};${expires};path=/`
  }
}
