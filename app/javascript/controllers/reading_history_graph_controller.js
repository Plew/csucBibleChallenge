import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["day"]

  showToast(event) {
    const dayElement = event.currentTarget
    const dayInfo = dayElement.dataset.dayInfo

    // Create toast container if it doesn't exist
    let toastContainer = document.getElementById('reading-graph-toast')
    if (!toastContainer) {
      toastContainer = document.createElement('div')
      toastContainer.id = 'reading-graph-toast'
      toastContainer.className = 'toast toast-center toast-middle z-50'
      document.body.appendChild(toastContainer)
    }

    // Create alert element
    const alert = document.createElement('div')
    alert.className = 'alert alert-info shadow-lg'
    alert.innerHTML = `<span>${dayInfo}</span>`

    // Add to toast container
    toastContainer.appendChild(alert)

    // Remove after 3 seconds
    setTimeout(() => {
      alert.style.transition = 'opacity 0.3s ease'
      alert.style.opacity = '0'
      setTimeout(() => {
        alert.remove()
        // Remove container if empty
        if (toastContainer.children.length === 0) {
          toastContainer.remove()
        }
      }, 300)
    }, 3000)
  }
}
