import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["monthTitle", "calendarGrid"]
  static values = {
    selectedDate: String,
    challengeId: Number
  }

  prevMonth(event) {
    const month = event.currentTarget.dataset.month
    this.loadMonth(month)
  }

  nextMonth(event) {
    const month = event.currentTarget.dataset.month
    this.loadMonth(month)
  }

  async loadMonth(monthDate) {
    try {
      const response = await fetch(`/date_picker?date=${monthDate}&challenge_id=${this.challengeIdValue}`, {
        headers: {
          'Accept': 'text/html',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })

      if (response.ok) {
        const html = await response.text()
        // Replace the entire component content
        this.element.outerHTML = html
      }
    } catch (error) {
      console.error('Error loading month:', error)
    }
  }

  selectDate(event) {
    // Close the modal when a date is selected
    const modal = this.element.closest('dialog')
    if (modal) {
      modal.close()
    }
  }
}
