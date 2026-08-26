import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox"]

  connect() {
    // 1. Determine the current theme
    this.theme = localStorage.getItem("theme") || this.getSystemTheme()
    this.applyTheme(this.theme)
    
    // 2. Listen for real-time OS changes (e.g., user toggles iOS Dark Mode)
    this.mediaQuery = window.matchMedia('(prefers-color-scheme: dark)')
    this.mediaQuery.addEventListener('change', this.handleSystemChange.bind(this))
  }

  disconnect() {
    this.mediaQuery.removeEventListener('change', this.handleSystemChange.bind(this))
  }

  // Triggered when the user clicks the toggle button
  toggle() {
    this.theme = this.theme === "andgodsaid" ? "andgodsaid-dark" : "andgodsaid"
    localStorage.setItem("theme", this.theme) // Save preference
    this.applyTheme(this.theme)
  }

  handleSystemChange(e) {
    // Only auto-switch if the user hasn't manually forced a preference
    if (!localStorage.getItem("theme")) {
      this.theme = e.matches ? "andgodsaid-dark" : "andgodsaid"
      this.applyTheme(this.theme)
    }
  }

  getSystemTheme() {
    return window.matchMedia('(prefers-color-scheme: dark)').matches ? "andgodsaid-dark" : "andgodsaid"
  }

  applyTheme(theme) {
    document.documentElement.setAttribute("data-theme", theme)
    // Keep the sun/moon UI checkbox in sync with the theme
    if (this.hasCheckboxTarget) {
      this.checkboxTarget.checked = theme === "andgodsaid-dark"
    }
  }
}