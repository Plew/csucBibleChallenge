import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { selectedDate: String }

  connect() {
    this.scrollToSelectedDate()
  }

  selectedDateValueChanged() {
    this.scrollToSelectedDate()
  }

  scrollToSelectedDate() {
    if (!this.selectedDateValue) return
    
    const selectedElement = this.element.querySelector(`[data-date="${this.selectedDateValue}"]`)
    if (selectedElement) {
      selectedElement.scrollIntoView({ 
        behavior: 'smooth', 
        block: 'nearest',
        inline: 'center' 
      })
    }
  }
}