import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "popover", "monthTitle", "calendarGrid"]
  static values = {
    selectedDate: String,
    challengeId: Number
  }

  connect() {
    this.closeHandler = this.handleClickOutside.bind(this)
    this.keydownHandler = this.handleKeydown.bind(this)
    document.addEventListener("click", this.closeHandler)
    document.addEventListener("keydown", this.keydownHandler)

    if (this.hasInputTarget) {
      const initialVal = this.inputTarget.value
      this.viewDate = initialVal ? this.parseDate(initialVal) : new Date()
      if (isNaN(this.viewDate.getTime())) {
        this.viewDate = new Date()
      }
      this.renderCalendar()
    }
  }

  disconnect() {
    document.removeEventListener("click", this.closeHandler)
    document.removeEventListener("keydown", this.keydownHandler)
  }

  handleClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }

  handleKeydown(event) {
    if (event.key === "Escape" && this.hasPopoverTarget && !this.popoverTarget.classList.contains("hidden")) {
      this.close()
    }
  }

  toggle(event) {
    if (event) {
      event.preventDefault()
      event.stopPropagation()
    }

    if (!this.hasPopoverTarget) return

    if (this.popoverTarget.classList.contains("hidden")) {
      this.open()
    } else {
      this.close()
    }
  }

  open() {
    if (!this.hasPopoverTarget) return

    const currentVal = this.hasInputTarget ? this.inputTarget.value : ""
    if (currentVal) {
      const parsed = this.parseDate(currentVal)
      if (!isNaN(parsed.getTime())) {
        this.viewDate = new Date(parsed.getFullYear(), parsed.getMonth(), 1)
      }
    }

    this.renderCalendar()
    this.popoverTarget.classList.remove("hidden")
  }

  close() {
    if (this.hasPopoverTarget) {
      this.popoverTarget.classList.add("hidden")
    }
  }

  prevMonth(event) {
    if (event) {
      event.preventDefault()
      event.stopPropagation()
    }

    // If challengeId is present, use AJAX loading (reading mode)
    if (this.hasChallengeIdValue && this.challengeIdValue) {
      const month = event.currentTarget.dataset.month
      this.loadMonth(month)
      return
    }

    // Form popover mode
    if (this.viewDate) {
      this.viewDate.setMonth(this.viewDate.getMonth() - 1)
      this.renderCalendar()
    }
  }

  nextMonth(event) {
    if (event) {
      event.preventDefault()
      event.stopPropagation()
    }

    // If challengeId is present, use AJAX loading (reading mode)
    if (this.hasChallengeIdValue && this.challengeIdValue) {
      const month = event.currentTarget.dataset.month
      this.loadMonth(month)
      return
    }

    // Form popover mode
    if (this.viewDate) {
      this.viewDate.setMonth(this.viewDate.getMonth() + 1)
      this.renderCalendar()
    }
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
        this.element.outerHTML = html
      }
    } catch (error) {
      console.error('Error loading month:', error)
    }
  }

  selectDate(event) {
    if (this.hasInputTarget) {
      if (event) {
        event.preventDefault()
        event.stopPropagation()
      }

      const dateStr = event.currentTarget.dataset.date
      if (dateStr) {
        this.inputTarget.value = dateStr
        this.inputTarget.dispatchEvent(new Event("input", { bubbles: true }))
        this.inputTarget.dispatchEvent(new Event("change", { bubbles: true }))
        this.renderCalendar()
        this.close()
      }
      return
    }

    // Close the modal when a date is selected in reading mode
    const modal = this.element.closest('dialog')
    if (modal) {
      modal.close()
    }
  }

  selectToday(event) {
    if (event) {
      event.preventDefault()
      event.stopPropagation()
    }

    const todayStr = this.formatDate(new Date())
    if (this.hasInputTarget) {
      this.inputTarget.value = todayStr
      this.inputTarget.dispatchEvent(new Event("input", { bubbles: true }))
      this.inputTarget.dispatchEvent(new Event("change", { bubbles: true }))
    }

    this.viewDate = new Date()
    this.renderCalendar()
    this.close()
  }

  clear(event) {
    if (event) {
      event.preventDefault()
      event.stopPropagation()
    }

    if (this.hasInputTarget) {
      this.inputTarget.value = ""
      this.inputTarget.dispatchEvent(new Event("input", { bubbles: true }))
      this.inputTarget.dispatchEvent(new Event("change", { bubbles: true }))
    }

    this.renderCalendar()
    this.close()
  }

  setPreset(event) {
    if (event) {
      event.preventDefault()
    }

    const dateStr = event.currentTarget.dataset.date
    if (!dateStr || !this.hasInputTarget) return

    this.inputTarget.value = dateStr
    this.inputTarget.dispatchEvent(new Event("input", { bubbles: true }))
    this.inputTarget.dispatchEvent(new Event("change", { bubbles: true }))

    const parsed = this.parseDate(dateStr)
    if (!isNaN(parsed.getTime())) {
      this.viewDate = new Date(parsed.getFullYear(), parsed.getMonth(), 1)
      this.renderCalendar()
    }
  }

  renderCalendar() {
    if (!this.hasMonthTitleTarget || !this.hasCalendarGridTarget || !this.viewDate) return

    const year = this.viewDate.getFullYear()
    const month = this.viewDate.getMonth()

    const monthNames = [
      "January", "February", "March", "April", "May", "June",
      "July", "August", "September", "October", "November", "December"
    ]
    this.monthTitleTarget.textContent = `${monthNames[month]} ${year}`

    const selectedVal = this.hasInputTarget ? this.inputTarget.value : ""
    const todayStr = this.formatDate(new Date())

    const firstDayIndex = new Date(year, month, 1).getDay() // 0 = Sun, 1 = Mon, ...
    const daysInMonth = new Date(year, month + 1, 0).getDate()
    const prevMonthDays = new Date(year, month, 0).getDate()

    let gridHtml = ""

    // 1. Previous month trailing days
    for (let i = firstDayIndex - 1; i >= 0; i--) {
      const dayNum = prevMonthDays - i
      const prevMonthDate = new Date(year, month - 1, dayNum)
      const dateStr = this.formatDate(prevMonthDate)
      gridHtml += `
        <button type="button"
                class="w-8 h-8 mx-auto flex items-center justify-center text-xs text-base-content/25 rounded-xl hover:bg-base-200 hover:text-base-content/50 transition-colors"
                data-action="click->date-picker#selectDate"
                data-date="${dateStr}">
          ${dayNum}
        </button>
      `
    }

    // 2. Current month days
    for (let day = 1; day <= daysInMonth; day++) {
      const dateObj = new Date(year, month, day)
      const dateStr = this.formatDate(dateObj)
      const isSelected = (dateStr === selectedVal)
      const isToday = (dateStr === todayStr)

      let btnClass = "w-8 h-8 mx-auto flex items-center justify-center text-xs rounded-xl font-medium transition-all cursor-pointer "

      if (isSelected) {
        btnClass += "bg-primary text-primary-content font-bold shadow-md ring-2 ring-primary ring-offset-1 ring-offset-base-100"
      } else if (isToday) {
        btnClass += "ring-1.5 ring-primary/60 text-primary font-bold bg-primary/10 hover:bg-primary/20"
      } else {
        btnClass += "text-neutral hover:bg-primary/15 hover:text-primary hover:font-semibold"
      }

      gridHtml += `
        <button type="button"
                class="${btnClass}"
                data-action="click->date-picker#selectDate"
                data-date="${dateStr}">
          ${day}
        </button>
      `
    }

    // 3. Next month leading days to complete the 7-column grid
    const totalCellsSoFar = firstDayIndex + daysInMonth
    const remainingCells = (totalCellsSoFar % 7 === 0) ? 0 : (7 - (totalCellsSoFar % 7))
    for (let nextDay = 1; nextDay <= remainingCells; nextDay++) {
      const nextMonthDate = new Date(year, month + 1, nextDay)
      const dateStr = this.formatDate(nextMonthDate)
      gridHtml += `
        <button type="button"
                class="w-8 h-8 mx-auto flex items-center justify-center text-xs text-base-content/25 rounded-xl hover:bg-base-200 hover:text-base-content/50 transition-colors"
                data-action="click->date-picker#selectDate"
                data-date="${dateStr}">
          ${nextDay}
        </button>
      `
    }

    this.calendarGridTarget.innerHTML = gridHtml
  }

  parseDate(dateStr) {
    if (!dateStr) return new Date()
    const parts = dateStr.split("-")
    if (parts.length === 3) {
      return new Date(parseInt(parts[0]), parseInt(parts[1]) - 1, parseInt(parts[2]))
    }
    return new Date(dateStr)
  }

  formatDate(date) {
    const year = date.getFullYear()
    const month = String(date.getMonth() + 1).padStart(2, "0")
    const day = String(date.getDate()).padStart(2, "0")
    return `${year}-${month}-${day}`
  }
}
