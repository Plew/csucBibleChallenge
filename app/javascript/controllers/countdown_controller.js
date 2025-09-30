import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["days", "hours", "minutes", "seconds"]
  static values = { target: String }

  connect() {
    this.startCountdown()
  }

  disconnect() {
    if (this.interval) {
      clearInterval(this.interval)
    }
  }

  startCountdown() {
    this.updateCountdown()
    this.interval = setInterval(() => {
      this.updateCountdown()
    }, 1000)
  }

  updateCountdown() {
    const targetDate = new Date(this.targetValue)
    const now = new Date()
    const timeDiff = targetDate - now

    if (timeDiff <= 0) {
      this.showCountdownEnded()
      clearInterval(this.interval)
      return
    }

    const days = Math.floor(timeDiff / (1000 * 60 * 60 * 24))
    const hours = Math.floor((timeDiff % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60))
    const minutes = Math.floor((timeDiff % (1000 * 60 * 60)) / (1000 * 60))
    const seconds = Math.floor((timeDiff % (1000 * 60)) / 1000)

    this.updateTimeUnit(this.daysTarget, days)
    this.updateTimeUnit(this.hoursTarget, hours)
    this.updateTimeUnit(this.minutesTarget, minutes)
    this.updateTimeUnit(this.secondsTarget, seconds)
  }

  updateTimeUnit(target, value) {
    const span = target.querySelector('span')
    if (span) {
      span.style.setProperty('--value', value)
      span.textContent = value
      span.setAttribute('aria-label', value)
    }
  }

  showCountdownEnded() {
    // Optionally reload the page when countdown ends to show the challenge has started
    setTimeout(() => {
      window.location.reload()
    }, 2000)
  }
}