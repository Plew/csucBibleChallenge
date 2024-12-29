import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    text: String
  }
  
  copy() {
    navigator.clipboard.writeText(this.textValue)
      .then(() => {
        // Optional: Add some visual feedback
        this.element.classList.add('text-green-600')
        setTimeout(() => {
          this.element.classList.remove('text-green-600')
        }, 1000)
      })
      .catch(err => {
        console.error('Failed to copy text: ', err)
      })
  }
} 