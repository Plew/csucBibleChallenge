import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["heart", "count"]
  static values = {
    readingId: Number,
    verseNumber: Number,
    liked: Boolean
  }

  connect() {
    this.longPressTimer = null
    this.longPressDuration = 500 // 500ms for long press
    this.updateHeartDisplay()
  }

  startPress(event) {
    event.preventDefault()

    this.longPressTimer = setTimeout(() => {
      this.toggleLike()
    }, this.longPressDuration)
  }

  endPress(event) {
    event.preventDefault()

    if (this.longPressTimer) {
      clearTimeout(this.longPressTimer)
      this.longPressTimer = null
    }
  }

  cancelPress(event) {
    if (this.longPressTimer) {
      clearTimeout(this.longPressTimer)
      this.longPressTimer = null
    }
  }

  async toggleLike() {
    const url = this.likedValue
      ? `/readings/${this.readingIdValue}/verse_likes/${this.verseNumberValue}`
      : `/readings/${this.readingIdValue}/verse_likes`

    const method = this.likedValue ? 'DELETE' : 'POST'

    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

    try {
      const response = await fetch(url, {
        method: method,
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': csrfToken,
          'Accept': 'application/json'
        },
        body: JSON.stringify({
          verse_number: this.verseNumberValue
        })
      })

      if (response.ok) {
        const data = await response.json()
        this.likedValue = data.liked
        this.updateHeartDisplay()
        this.updateCount(data.like_count)
        this.animateHeart()
      }
    } catch (error) {
      console.error('Error toggling like:', error)
    }
  }

  updateHeartDisplay() {
    if (this.hasHeartTarget) {
      if (this.likedValue) {
        this.heartTarget.innerHTML = '❤️'
        this.heartTarget.classList.add('text-red-500')
      } else {
        this.heartTarget.innerHTML = '🤍'
        this.heartTarget.classList.remove('text-red-500')
      }
    }
  }

  updateCount(count) {
    if (this.hasCountTarget) {
      if (count > 0) {
        this.countTarget.textContent = count
        this.countTarget.classList.remove('hidden')
      } else {
        this.countTarget.classList.add('hidden')
      }
    }
  }

  animateHeart() {
    if (this.hasHeartTarget) {
      this.heartTarget.classList.add('scale-125')
      setTimeout(() => {
        this.heartTarget.classList.remove('scale-125')
      }, 200)
    }
  }
}
