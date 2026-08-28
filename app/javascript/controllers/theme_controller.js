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
    this.theme = theme
    document.documentElement.setAttribute("data-theme", theme)
    // Use 'only light' / 'only dark' to prevent Android Edge / Chrome auto-dark mode from inverting light theme
    document.documentElement.style.colorScheme = (theme === "andgodsaid-dark") ? "only dark" : "only light"

    // Update meta color-scheme
    const metaColorScheme = document.querySelector('meta[name="color-scheme"]')
    if (metaColorScheme) {
      metaColorScheme.setAttribute("content", theme === "andgodsaid-dark" ? "dark" : "light")
    }

    // Update meta theme-color for browser navigation bar
    const metaThemeColor = document.querySelector('meta[name="theme-color"]')
    if (metaThemeColor) {
      metaThemeColor.setAttribute("content", theme === "andgodsaid-dark" ? "#1C1A17" : "#6B7558")
    }

    // Keep the sun/moon UI checkbox in sync with the theme
    if (this.hasCheckboxTarget) {
      this.checkboxTarget.checked = (theme === "andgodsaid-dark")
    }
  }
}