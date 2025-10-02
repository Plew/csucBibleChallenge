import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    url: String,
    title: String,
    text: String
  }

  async share() {
    const shareData = {
      title: this.titleValue,
      text: this.textValue,
      url: this.urlValue
    }

    // Check if Web Share API is supported (primarily mobile devices)
    if (navigator.share) {
      try {
        await navigator.share(shareData)
        this.showFeedback('Shared successfully!', 'success')
      } catch (err) {
        // User cancelled the share or there was an error
        if (err.name !== 'AbortError') {
          console.error('Error sharing:', err)
          this.fallbackToCopy()
        }
      }
    } else {
      // Fallback to copying to clipboard
      this.fallbackToCopy()
    }
  }

  fallbackToCopy() {
    const textToCopy = `${this.textValue}\n${this.urlValue}`

    navigator.clipboard.writeText(textToCopy)
      .then(() => {
        this.showFeedback('Link copied to clipboard!', 'success')
      })
      .catch(err => {
        console.error('Failed to copy:', err)
        this.showFeedback('Failed to copy link', 'error')
      })
  }

  showFeedback(message, type) {
    // Create a temporary flash message
    const flashContainer = document.createElement('div')
    flashContainer.className = `fixed top-20 left-4 right-4 z-50 bg-${type === 'success' ? 'primary' : 'error'} text-${type === 'success' ? 'primary' : 'error'}-content shadow-lg rounded-box px-4 py-3`
    flashContainer.innerHTML = `
      <div class="flex items-center justify-between">
        <span>${message}</span>
      </div>
    `

    document.body.appendChild(flashContainer)

    // Fade in animation
    setTimeout(() => {
      flashContainer.style.opacity = '1'
      flashContainer.style.transform = 'translateY(0)'
    }, 10)

    // Remove after 2 seconds
    setTimeout(() => {
      flashContainer.style.opacity = '0'
      flashContainer.style.transform = 'translateY(-1rem)'
      setTimeout(() => {
        document.body.removeChild(flashContainer)
      }, 300)
    }, 2000)
  }
}
