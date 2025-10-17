import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["card", "startButton", "cardsContainer", "winnerAnnouncement", "winnerName", "winnerAvatar"]

  connect() {
    this.isRunning = false
    this.remainingCards = [...this.cardTargets]
  }

  startElimination() {
    if (this.isRunning) return

    this.isRunning = true
    this.startButtonTarget.disabled = true
    this.startButtonTarget.classList.add('btn-disabled')

    this.eliminateNext()
  }

  async eliminateNext() {
    if (this.remainingCards.length === 1) {
      // We have a winner!
      this.showWinner(this.remainingCards[0])
      return
    }

    // Flash all remaining cards randomly for 5 seconds (20% slower = 5x original time)
    await this.flashCards(5000)

    // Select a random card to eliminate
    const randomIndex = Math.floor(Math.random() * this.remainingCards.length)
    const cardToEliminate = this.remainingCards[randomIndex]

    // Highlight the selected card
    cardToEliminate.classList.add('ring-4', 'ring-error', 'bg-error', 'text-error-content')

    // Wait 1 second before sliding off
    await this.wait(1000)

    // Slide off animation with transition
    cardToEliminate.style.transition = 'all 1.5s ease-in-out'
    cardToEliminate.style.transform = 'translateX(200%) rotate(20deg)'
    cardToEliminate.style.opacity = '0'

    // Wait for animation to complete
    await this.wait(1500)

    // Remove from DOM and remaining cards array
    cardToEliminate.remove()
    this.remainingCards.splice(randomIndex, 1)

    // Wait 3 seconds before next elimination
    await this.wait(3000)

    // Continue with next elimination
    this.eliminateNext()
  }

  async flashCards(duration) {
    const startTime = Date.now()
    const flashInterval = 500 // Flash every 500ms (slower)

    while (Date.now() - startTime < duration) {
      // Randomly highlight cards
      this.remainingCards.forEach(card => {
        if (Math.random() > 0.5) {
          card.classList.add('ring-2', 'ring-primary', 'scale-105')
        } else {
          card.classList.remove('ring-2', 'ring-primary', 'scale-105')
        }
      })

      await this.wait(flashInterval)
    }

    // Clear all highlights
    this.remainingCards.forEach(card => {
      card.classList.remove('ring-2', 'ring-primary', 'scale-105')
    })
  }

  showWinner(winnerCard) {
    // Highlight winner card with special effect
    winnerCard.classList.add('ring-8', 'ring-success', 'bg-success', 'text-success-content', 'scale-110')

    // Get winner name from card
    const winnerName = winnerCard.querySelector('p').textContent
    const userId = winnerCard.dataset.userId

    // Show winner announcement
    this.winnerNameTarget.textContent = winnerName

    // Update winner avatar if available
    const winnerAvatarImg = winnerCard.querySelector('img')
    if (winnerAvatarImg && this.hasWinnerAvatarTarget) {
      this.winnerAvatarTarget.src = winnerAvatarImg.src
      this.winnerAvatarTarget.classList.remove('hidden')
    }

    this.winnerAnnouncementTarget.classList.remove('hidden')

    // Animate the announcement
    this.winnerAnnouncementTarget.style.opacity = '0'
    this.winnerAnnouncementTarget.style.transform = 'scale(0.8)'

    setTimeout(() => {
      this.winnerAnnouncementTarget.style.transition = 'all 0.5s ease-out'
      this.winnerAnnouncementTarget.style.opacity = '1'
      this.winnerAnnouncementTarget.style.transform = 'scale(1)'
    }, 100)
  }

  wait(ms) {
    return new Promise(resolve => setTimeout(resolve, ms))
  }
}
