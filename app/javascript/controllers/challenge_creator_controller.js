import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "startDate",
    "bookCheckbox",
    "schedulePreview",
    "scheduleContent",
    "stepper",
    "selectionSummary",
    "chaptersPerDay",
    "readingDayCheckbox",
    "skipDayCheckbox",
    "skipDatesText"
  ]

  static presets = {
    whole_bible: Array.from({ length: 66 }, (_, i) => i + 1),
    gospels: [ 40, 41, 42, 43 ],
    gospels_acts: [ 40, 41, 42, 43, 44 ],
    pauline: [ 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57 ],
    wisdom: [ 18, 19, 20, 21, 22 ],
    pentateuch: [ 1, 2, 3, 4, 5 ]
  }

  connect() {
    this.updateSchedule()
    this.setupStepObserver()
  }

  selectPreset(event) {
    const presetName = event.currentTarget.dataset.preset
    const bookNumbers = this.constructor.presets[presetName]
    if (!bookNumbers) return

    this.bookCheckboxTargets.forEach(checkbox => {
      checkbox.checked = bookNumbers.includes(parseInt(checkbox.value))
    })
    this.updateSchedule()
  }

  selectAllBooks() {
    this.bookCheckboxTargets.forEach(checkbox => {
      checkbox.checked = true
    })
    this.updateSchedule()
  }

  selectOldTestament() {
    this.bookCheckboxTargets.forEach(checkbox => {
      checkbox.checked = (checkbox.dataset.testament === "old")
    })
    this.updateSchedule()
  }

  selectNewTestament() {
    this.bookCheckboxTargets.forEach(checkbox => {
      checkbox.checked = (checkbox.dataset.testament === "new")
    })
    this.updateSchedule()
  }

  clearAllBooks() {
    this.bookCheckboxTargets.forEach(checkbox => {
      checkbox.checked = false
    })
    this.updateSchedule()
  }

  setAllDays() {
    if (this.hasReadingDayCheckboxTargets) {
      this.readingDayCheckboxTargets.forEach(cb => { cb.checked = true })
    } else if (this.hasSkipDayCheckboxTargets) {
      this.skipDayCheckboxTargets.forEach(cb => { cb.checked = false })
    }
    this.updateSchedule()
  }

  setWeekdaysOnly() {
    if (this.hasReadingDayCheckboxTargets) {
      this.readingDayCheckboxTargets.forEach(cb => {
        const wday = parseInt(cb.dataset.wday)
        cb.checked = (wday >= 1 && wday <= 5) // Mon (1) through Fri (5)
      })
    } else if (this.hasSkipDayCheckboxTargets) {
      this.skipDayCheckboxTargets.forEach(cb => {
        const wday = parseInt(cb.dataset.wday)
        cb.checked = (wday === 0 || wday === 6) // Skip Sun and Sat
      })
    }
    this.updateSchedule()
  }

  setSkipSundays() {
    if (this.hasReadingDayCheckboxTargets) {
      this.readingDayCheckboxTargets.forEach(cb => {
        const wday = parseInt(cb.dataset.wday)
        cb.checked = (wday !== 0) // Mon-Sat checked, Sun unchecked
      })
    } else if (this.hasSkipDayCheckboxTargets) {
      this.skipDayCheckboxTargets.forEach(cb => {
        const wday = parseInt(cb.dataset.wday)
        cb.checked = (wday === 0) // Skip Sun
      })
    }
    this.updateSchedule()
  }

  scrollToSection(event) {
    const sectionId = event.currentTarget.dataset.section
    const section = document.getElementById(sectionId)
    if (section) {
      section.scrollIntoView({ behavior: "smooth", block: "start" })
    }
  }

  setupStepObserver() {
    if (!this.hasStepperTarget) return

    const sections = [
      document.getElementById("section-details"),
      document.getElementById("section-books"),
      document.getElementById("section-preview")
    ].filter(Boolean)

    if (sections.length === 0) return

    const observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          const sectionId = entry.target.id
          this.updateStepper(sectionId)
        }
      })
    }, { threshold: 0.3 })

    sections.forEach(section => observer.observe(section))
  }

  updateStepper(activeSectionId) {
    if (!this.hasStepperTarget) return

    const steps = this.stepperTarget.querySelectorAll(".step")
    const sectionOrder = [ "section-details", "section-books", "section-preview" ]
    const activeIndex = sectionOrder.indexOf(activeSectionId)

    steps.forEach((step, index) => {
      if (index <= activeIndex) {
        step.classList.add("step-primary")
      } else {
        step.classList.remove("step-primary")
      }
    })
  }

  updateSelectionSummary() {
    if (!this.hasSelectionSummaryTarget) return

    const selected = this.bookCheckboxTargets.filter(cb => cb.checked)
    if (selected.length === 0) {
      this.selectionSummaryTarget.style.display = "none"
      return
    }

    const totalChapters = selected.reduce((sum, cb) => sum + parseInt(cb.dataset.chapters), 0)
    this.selectionSummaryTarget.textContent = `${selected.length} books selected (${totalChapters} chapters)`
    this.selectionSummaryTarget.style.display = "block"
  }

  updateSchedule() {
    this.updateSelectionSummary()
    if (!this.hasStartDateTarget) return
    const startDate = this.startDateTarget.value
    const selectedBooks = this.getSelectedBooks()

    if (!startDate || selectedBooks.length === 0) {
      if (this.hasSchedulePreviewTarget) {
        this.schedulePreviewTarget.style.display = "none"
      }
      return
    }

    const schedule = this.generateSchedule(startDate, selectedBooks)
    this.displaySchedule(schedule)
    if (this.hasSchedulePreviewTarget) {
      this.schedulePreviewTarget.style.display = "block"
    }
  }

  getSelectedBooks() {
    return this.bookCheckboxTargets
      .filter(checkbox => checkbox.checked)
      .map(checkbox => ({
        number: parseInt(checkbox.value),
        name: checkbox.parentElement.querySelector('span').textContent.split(' (')[0].trim(),
        chapters: parseInt(checkbox.dataset.chapters)
      }))
      .sort((a, b) => a.number - b.number)
  }

  getSkipDays() {
    if (this.hasReadingDayCheckboxTargets) {
      const readingDays = this.readingDayCheckboxTargets
        .filter(cb => cb.checked)
        .map(cb => parseInt(cb.dataset.wday))
      return [0, 1, 2, 3, 4, 5, 6].filter(day => !readingDays.includes(day))
    }
    if (this.hasSkipDayCheckboxTargets) {
      return this.skipDayCheckboxTargets
        .filter(cb => cb.checked)
        .map(cb => parseInt(cb.dataset.wday))
    }
    return []
  }

  getSkipDates() {
    if (!this.hasSkipDatesTextTarget || !this.skipDatesTextTarget.value) return []
    const raw = this.skipDatesTextTarget.value
    const dates = []
    raw.split(/[\n,;]+/).forEach(s => {
      const trimmed = s.trim()
      if (trimmed && /^\d{4}-\d{2}-\d{2}$/.test(trimmed)) {
        dates.push(trimmed)
      }
    })
    return dates
  }

  parseLocalDate(dateStr) {
    const parts = dateStr.split('-')
    return new Date(parseInt(parts[0]), parseInt(parts[1]) - 1, parseInt(parts[2]))
  }

  formatDateYYYYMMDD(date) {
    const year = date.getFullYear()
    const month = String(date.getMonth() + 1).padStart(2, '0')
    const day = String(date.getDate()).padStart(2, '0')
    return `${year}-${month}-${day}`
  }

  generateSchedule(startDateStr, selectedBooks) {
    const startDate = this.parseLocalDate(startDateStr)
    const chaptersPerDay = parseInt(this.hasChaptersPerDayTarget ? this.chaptersPerDayTarget.value : 1) || 1
    const skipDays = this.getSkipDays()
    const skipDates = this.getSkipDates()

    // Flatten all chapters in sequence
    const allChapters = []
    selectedBooks.forEach(book => {
      for (let ch = 1; ch <= book.chapters; ch++) {
        allChapters.push({
          book: book.name,
          chapter: ch,
          bookNumber: book.number
        })
      }
    })

    const schedule = []
    let currentDate = new Date(startDate)

    while (allChapters.length > 0) {
      const dateStr = this.formatDateYYYYMMDD(currentDate)
      const dayOfWeek = currentDate.getDay() // 0 = Sun, 1 = Mon, ...

      if (skipDays.includes(dayOfWeek) || skipDates.includes(dateStr)) {
        currentDate.setDate(currentDate.getDate() + 1)
        continue
      }

      const count = Math.min(chaptersPerDay, allChapters.length)
      for (let i = 0; i < count; i++) {
        const item = allChapters.shift()
        schedule.push({
          date: new Date(currentDate),
          book: item.book,
          chapter: item.chapter,
          bookNumber: item.bookNumber
        })
      }

      if (allChapters.length > 0) {
        currentDate.setDate(currentDate.getDate() + 1)
      }
    }

    return schedule
  }

  displaySchedule(schedule) {
    if (!this.hasScheduleContentTarget || !schedule || schedule.length === 0) return

    const totalChapters = schedule.length
    const startDate = schedule[0].date
    const endDate = schedule[schedule.length - 1].date

    // Group schedule items by date
    const groupedByDate = new Map()
    schedule.forEach(item => {
      const dateKey = this.formatDateYYYYMMDD(item.date)
      if (!groupedByDate.has(dateKey)) {
        groupedByDate.set(dateKey, { date: item.date, chapters: [] })
      }
      groupedByDate.get(dateKey).chapters.push(item)
    })

    const readingDaysCount = groupedByDate.size
    const calendarDaysCount = Math.round((endDate - startDate) / (1000 * 60 * 60 * 24)) + 1
    const chaptersPerDay = parseInt(this.hasChaptersPerDayTarget ? this.chaptersPerDayTarget.value : 1) || 1

    let html = `
      <div class="stats stats-vertical sm:stats-horizontal shadow mb-6 w-full bg-base-200">
        <div class="stat py-3">
          <div class="stat-title text-xs">Total Chapters</div>
          <div class="stat-value text-xl sm:text-2xl">${totalChapters}</div>
          <div class="stat-desc">${chaptersPerDay} / day</div>
        </div>
        <div class="stat py-3">
          <div class="stat-title text-xs">Reading Days</div>
          <div class="stat-value text-xl sm:text-2xl text-primary">${readingDaysCount}</div>
          <div class="stat-desc">${calendarDaysCount} calendar days</div>
        </div>
        <div class="stat py-3">
          <div class="stat-title text-xs">End Date</div>
          <div class="stat-value text-sm sm:text-base font-semibold text-neutral">${this.formatDate(endDate)}</div>
          <div class="stat-desc">Starts ${this.formatDate(startDate)}</div>
        </div>
      </div>
    `

    const dateEntries = Array.from(groupedByDate.values())

    html += '<div class="space-y-2">'
    html += '<p class="text-xs font-semibold text-neutral/70 uppercase tracking-wider mb-2">Sample Reading Schedule:</p>'

    const sampleEntries = dateEntries.slice(0, 10)
    sampleEntries.forEach(entry => {
      const chapterTitles = entry.chapters.map(c => `${c.book} ${c.chapter}`).join(", ")
      html += `
        <div class="flex justify-between items-center p-2.5 bg-base-200 rounded-xl border border-base-300/60 text-xs sm:text-sm">
          <span class="font-medium text-neutral">${this.formatDate(entry.date)}</span>
          <span class="badge badge-primary badge-outline badge-sm py-2 px-2.5 font-medium">${chapterTitles}</span>
        </div>
      `
    })

    if (dateEntries.length > 10) {
      html += `<div class="text-center py-2 text-xs text-base-content/60 font-medium">+ ${dateEntries.length - 10} more reading days</div>`
    }
    html += '</div>'

    this.scheduleContentTarget.innerHTML = html
  }

  formatDate(date) {
    return date.toLocaleDateString('en-US', {
      weekday: 'short',
      month: 'short',
      day: 'numeric',
      year: 'numeric'
    })
  }
}
