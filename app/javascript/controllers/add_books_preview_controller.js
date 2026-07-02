import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["bookCheckbox", "preview", "prompt", "chapterCount", "endDate", "submit"]
  static values = { lastReadingDate: String }

  connect() {
    this.update()
  }

  update() {
    const totalChapters = this.bookCheckboxTargets
      .filter(checkbox => checkbox.checked)
      .reduce((sum, checkbox) => sum + parseInt(checkbox.dataset.chapters, 10), 0)

    this.submitTarget.disabled = totalChapters === 0

    if (totalChapters === 0) {
      this.previewTarget.style.display = "none"
      this.promptTarget.style.display = "block"
      return
    }

    const newEndDate = new Date(`${this.lastReadingDateValue}T00:00:00`)
    newEndDate.setDate(newEndDate.getDate() + totalChapters)

    this.chapterCountTarget.textContent = totalChapters
    this.endDateTarget.textContent = newEndDate.toLocaleDateString(undefined, {
      year: "numeric",
      month: "long",
      day: "numeric"
    })
    this.previewTarget.style.display = "block"
    this.promptTarget.style.display = "none"
  }
}
