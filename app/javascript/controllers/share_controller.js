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
    // Create a temporary flash message using DaisyUI alert classes
    const isDesktop = window.innerWidth >= 768
    const alertClass = type === 'success' ? 'alert-success' : 'alert-error'
    const flashContainer = document.createElement('div')
    flashContainer.className = `fixed ${isDesktop ? 'bottom-6 right-6 max-w-md' : 'top-4 left-4 right-4'} z-50 alert ${alertClass} shadow-xl rounded-2xl border border-base-content/10 px-4 py-3 transition-all duration-300 opacity-0 transform ${isDesktop ? 'translate-y-4' : '-translate-y-4'} flex items-center justify-between gap-3 text-sm`
    
    const iconSvg = type === 'success'
      ? `<svg xmlns="http://www.w3.org/2000/svg" class="stroke-current shrink-0 h-5 w-5" fill="none" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>`
      : `<svg xmlns="http://www.w3.org/2000/svg" class="stroke-current shrink-0 h-5 w-5" fill="none" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>`

    flashContainer.innerHTML = `
      <div class="flex items-center gap-2">
        ${iconSvg}
        <span>${message}</span>
      </div>
    `

    document.body.appendChild(flashContainer)

    // Fade in animation
    setTimeout(() => {
      flashContainer.style.opacity = '1'
      flashContainer.style.transform = 'translateY(0)'
    }, 10)

    // Remove after 2.5 seconds
    setTimeout(() => {
      flashContainer.style.opacity = '0'
      flashContainer.style.transform = isDesktop ? 'translateY(1rem)' : 'translateY(-1rem)'
      setTimeout(() => {
        if (flashContainer.parentNode) {
          flashContainer.parentNode.removeChild(flashContainer)
        }
      }, 300)
    }, 2500)
  }
}
