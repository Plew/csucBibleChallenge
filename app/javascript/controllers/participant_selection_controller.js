import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox"]

  selectAll() {
    this.checkboxTargets.forEach(checkbox => {
      checkbox.checked = true
    })
  }

  selectNone() {
    this.checkboxTargets.forEach(checkbox => {
      checkbox.checked = false
    })
  }
}
