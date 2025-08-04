import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["startDate", "bookCheckbox", "schedulePreview", "scheduleContent"]

  connect() {
    this.updateSchedule()
  }

  selectOldTestament() {
    this.bookCheckboxTargets.forEach(checkbox => {
      if (checkbox.dataset.testament === "old") {
        checkbox.checked = true
      }
    })
    this.updateSchedule()
  }

  selectNewTestament() {
    this.bookCheckboxTargets.forEach(checkbox => {
      if (checkbox.dataset.testament === "new") {
        checkbox.checked = true
      }
    })
    this.updateSchedule()
  }

  clearAllBooks() {
    this.bookCheckboxTargets.forEach(checkbox => {
      checkbox.checked = false
    })
    this.updateSchedule()
  }

  updateSchedule() {
    const startDate = this.startDateTarget.value
    const selectedBooks = this.getSelectedBooks()

    if (!startDate || selectedBooks.length === 0) {
      this.schedulePreviewTarget.style.display = "none"
      return
    }

    const schedule = this.generateSchedule(startDate, selectedBooks)
    this.displaySchedule(schedule)
    this.schedulePreviewTarget.style.display = "block"
  }

  getSelectedBooks() {
    return this.bookCheckboxTargets
      .filter(checkbox => checkbox.checked)
      .map(checkbox => ({
        number: parseInt(checkbox.value),
        name: checkbox.parentElement.querySelector('span').textContent.split(' (')[0],
        chapters: parseInt(checkbox.dataset.chapters)
      }))
      .sort((a, b) => a.number - b.number)
  }

  generateSchedule(startDateStr, selectedBooks) {
    const startDate = new Date(startDateStr)
    const schedule = []
    let currentDate = new Date(startDate)

    selectedBooks.forEach(book => {
      for (let chapter = 1; chapter <= book.chapters; chapter++) {
        schedule.push({
          date: new Date(currentDate),
          book: book.name,
          chapter: chapter,
          bookNumber: book.number
        })
        currentDate.setDate(currentDate.getDate() + 1)
      }
    })

    return schedule
  }

  displaySchedule(schedule) {
    const totalChapters = schedule.length
    const startDate = schedule[0]?.date
    const endDate = schedule[schedule.length - 1]?.date
    
    let html = `
      <div class="stats shadow mb-6">
        <div class="stat">
          <div class="stat-title">Total Chapters</div>
          <div class="stat-value">${totalChapters}</div>
        </div>
        <div class="stat">
          <div class="stat-title">Duration</div>
          <div class="stat-value">${totalChapters} days</div>
        </div>
        <div class="stat">
          <div class="stat-title">End Date</div>
          <div class="stat-value text-sm">${this.formatDate(endDate)}</div>
        </div>
      </div>
    `

    if (schedule.length <= 20) {
      // Show first few days for shorter challenges
      html += '<div class="space-y-2">'
      schedule.slice(0, 10).forEach(item => {
        html += `
          <div class="flex justify-between items-center p-2 bg-base-200 rounded">
            <span class="font-medium">${this.formatDate(item.date)}</span>
            <span>${item.book} ${item.chapter}</span>
          </div>
        `
      })
      if (schedule.length > 10) {
        html += '<div class="text-center py-2 text-base-content/60">... and more</div>'
      }
      html += '</div>'
    } else {
      // Show summary for longer challenges
      html += '<div class="text-sm text-base-content/80">'
      html += '<p class="mb-2">Sample reading schedule:</p>'
      html += '<div class="space-y-1">'
      schedule.slice(0, 5).forEach(item => {
        html += `
          <div class="flex justify-between items-center p-2 bg-base-200 rounded text-xs">
            <span>${this.formatDate(item.date)}</span>
            <span>${item.book} ${item.chapter}</span>
          </div>
        `
      })
      html += '<div class="text-center py-2 text-base-content/60">... continuing daily through all selected books</div>'
      html += '</div></div>'
    }

    this.scheduleContentTarget.innerHTML = html
  }

  formatDate(date) {
    return date.toLocaleDateString('en-US', { 
      weekday: 'short', 
      month: 'short', 
      day: 'numeric' 
    })
  }
}