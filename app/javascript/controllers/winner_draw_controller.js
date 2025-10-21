import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["card", "startButton", "cardsContainer", "winnerAnnouncement", "winnerName", "winnerAvatar",
                    "leftPile", "rightPile"]

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
    // Get cards in each pile
    const leftCards = Array.from(this.leftPileTarget.querySelectorAll('[data-winner-draw-target="card"]'))
    const rightCards = Array.from(this.rightPileTarget.querySelectorAll('[data-winner-draw-target="card"]'))

    // Check if we have a winner (only one card left)
    if (leftCards.length + rightCards.length === 1) {
      const winnerCard = leftCards.length > 0 ? leftCards[0] : rightCards[0]
      this.showWinner(winnerCard)
      return
    }

    // Check if one pile is empty - if so, redistribute cards
    if (leftCards.length === 0 || rightCards.length === 0) {
      await this.redistributeCards(leftCards, rightCards)
      // Restart elimination with redistributed cards
      await this.wait(1000)
      this.eliminateNext()
      return
    }

    // Alternate selector between left and right for 5 seconds
    await this.alternateSelector(5000)

    // Randomly choose which pile to eliminate (50/50 chance)
    const eliminateLeft = Math.random() < 0.5
    const pileToEliminate = eliminateLeft ? leftCards : rightCards
    const pileToKeep = eliminateLeft ? rightCards : leftCards
    const pileElement = eliminateLeft ? this.leftPileTarget : this.rightPileTarget

    // Highlight the selected pile
    pileElement.classList.add('ring-4', 'ring-error', 'bg-error/10')

    // Wait 1 second before scattering
    await this.wait(1000)

    // Scatter the eliminated cards in all directions
    await this.scatterCards(pileToEliminate)

    // Remove the scattered cards from DOM
    pileToEliminate.forEach(card => card.remove())

    // Clear pile highlight
    pileElement.classList.remove('ring-4', 'ring-error', 'bg-error/10')

    // Wait before redistributing
    await this.wait(500)

    // Redistribute remaining cards into two piles
    await this.redistributeCards(eliminateLeft ? [] : leftCards, eliminateLeft ? rightCards : [])

    // Wait 2 seconds before next round
    await this.wait(2000)

    // Continue with next elimination
    this.eliminateNext()
  }

  async alternateSelector(duration) {
    const startTime = Date.now()
    let isLeft = true
    let switchCount = 0

    // Start fast (100ms) and gradually slow down over 5 seconds
    const minInterval = 100  // Start at 100ms
    const maxInterval = 800  // End at 800ms

    while (Date.now() - startTime < duration) {
      // Calculate progress (0 to 1)
      const progress = (Date.now() - startTime) / duration

      // Ease-out function for smooth deceleration
      const easeProgress = 1 - Math.pow(1 - progress, 3)

      // Calculate current interval based on progress
      const currentInterval = minInterval + (maxInterval - minInterval) * easeProgress

      // Toggle highlighting
      if (isLeft) {
        this.leftPileTarget.classList.add('ring-2', 'ring-primary')
        this.rightPileTarget.classList.remove('ring-2', 'ring-primary')
      } else {
        this.rightPileTarget.classList.add('ring-2', 'ring-primary')
        this.leftPileTarget.classList.remove('ring-2', 'ring-primary')
      }

      isLeft = !isLeft
      switchCount++
      await this.wait(currentInterval)
    }

    // Clear all highlights
    this.leftPileTarget.classList.remove('ring-2', 'ring-primary')
    this.rightPileTarget.classList.remove('ring-2', 'ring-primary')
  }

  async scatterCards(cards) {
    // Create random scatter animations for each card
    cards.forEach(card => {
      const angle = Math.random() * 360
      const distance = 300 + Math.random() * 500
      const rotation = Math.random() * 720 - 360

      const dx = Math.cos(angle * Math.PI / 180) * distance
      const dy = Math.sin(angle * Math.PI / 180) * distance

      card.style.transition = 'all 3s ease-out' // Much slower: 3 seconds
      card.style.transform = `translate(${dx}px, ${dy}px) rotate(${rotation}deg)`
      card.style.opacity = '0'
    })

    // Wait for scatter animation to complete
    await this.wait(3000)
  }

  async redistributeCards(leftCards, rightCards) {
    // Get all remaining cards
    const allCards = [...leftCards, ...rightCards]

    if (allCards.length === 0) return

    // Store original positions before moving
    const cardPositions = allCards.map(card => {
      const rect = card.getBoundingClientRect()
      return {
        card: card,
        x: rect.left,
        y: rect.top
      }
    })

    // Clear both piles
    this.leftPileTarget.innerHTML = ''
    this.rightPileTarget.innerHTML = ''

    // Redistribute cards evenly
    allCards.forEach((card, index) => {
      // Remove any old highlights
      card.classList.remove('ring-4', 'ring-error', 'bg-error', 'text-error-content')

      // Add to left or right pile
      if (index % 2 === 0) {
        this.leftPileTarget.appendChild(card)
      } else {
        this.rightPileTarget.appendChild(card)
      }
    })

    // Wait for layout to settle
    await this.wait(10)

    // Animate cards from old position to new position
    allCards.forEach((card, index) => {
      const oldPos = cardPositions[index]
      const newRect = card.getBoundingClientRect()

      const deltaX = oldPos.x - newRect.left
      const deltaY = oldPos.y - newRect.top

      // Start at old position
      card.style.transition = 'none'
      card.style.transform = `translate(${deltaX}px, ${deltaY}px)`
      card.style.opacity = '1'

      // Force reflow
      card.offsetHeight

      // Animate to new position
      card.style.transition = 'all 1s ease-out'
      card.style.transform = 'none'
    })

    await this.wait(1000)
  }

  showWinner(winnerCard) {
    // Get winner name from card data attribute
    const winnerName = winnerCard.dataset.userName

    // Show winner announcement
    this.winnerNameTarget.textContent = winnerName
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
