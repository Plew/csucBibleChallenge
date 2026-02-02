import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "startButton",
    "arcade",
    "ghostsContainer",
    "ghost",
    "pacman",
    "chompEffect",
    "powerMode",
    "winnerAnnouncement",
    "winnerName",
    "score",
    "scoreValue"
  ]

  connect() {
    this.isRunning = false
    this.remainingGhosts = [...this.ghostTargets]
    this.score = 0
    this.extraPacmans = []
  }

  startGame() {
    if (this.isRunning) return

    this.isRunning = true
    this.startButtonTarget.disabled = true
    this.startButtonTarget.classList.add('hidden')

    // Start the elimination sequence
    this.eliminateNext()
  }

  // Calculate how many Pac-Mans should attack this round
  getPacmanCount() {
    const ghostCount = this.remainingGhosts.length
    // 1 pacman per 5 ghosts, minimum 1
    return Math.max(1, Math.floor(ghostCount / 5))
  }

  async eliminateNext() {
    // Check if we have a winner (only one ghost left)
    if (this.remainingGhosts.length === 1) {
      await this.wait(500)
      this.showWinner(this.remainingGhosts[0])
      return
    }

    const pacmanCount = this.getPacmanCount()
    // Don't eliminate more ghosts than we have (minus 1 for the winner)
    const victimsToEliminate = Math.min(pacmanCount, this.remainingGhosts.length - 1)

    // Pick random ghosts to eliminate
    const victims = []
    const availableGhosts = [...this.remainingGhosts]
    for (let i = 0; i < victimsToEliminate; i++) {
      const victimIndex = Math.floor(Math.random() * availableGhosts.length)
      victims.push(availableGhosts[victimIndex])
      availableGhosts.splice(victimIndex, 1)
    }

    // Make non-victim ghosts "scared" - turn blue like in the game
    this.remainingGhosts.forEach(ghost => {
      if (!victims.includes(ghost)) {
        ghost.classList.add('ghost-scared')
      }
    })

    // Show power mode indicator
    this.powerModeTarget.classList.remove('hidden')

    // Ensure we have enough pacman elements
    this.ensurePacmanElements(victimsToEliminate)

    // Launch all pacmans simultaneously towards their victims
    const pacmanPromises = victims.map((victim, index) => {
      return this.attackWithPacman(victim, index)
    })

    // Wait for all pacmans to complete their attacks
    await Promise.all(pacmanPromises)

    // Remove victims from remaining ghosts
    victims.forEach(victim => {
      this.remainingGhosts = this.remainingGhosts.filter(g => g !== victim)
    })

    // Remove scared state and hide power mode
    this.remainingGhosts.forEach(ghost => {
      ghost.classList.remove('ghost-scared')
    })
    this.powerModeTarget.classList.add('hidden')

    // Wait before next round
    await this.wait(800)

    // Continue elimination
    this.eliminateNext()
  }

  // Ensure we have enough pacman elements for the attack
  ensurePacmanElements(count) {
    const existingCount = 1 + this.extraPacmans.length

    for (let i = existingCount; i < count; i++) {
      const newPacman = document.createElement('div')
      newPacman.className = 'absolute hidden'
      newPacman.style.top = '50%'
      newPacman.style.left = '-100px'
      newPacman.innerHTML = `
        <div class="pacman-body">
          <div class="pacman-top"></div>
          <div class="pacman-bottom"></div>
        </div>
      `
      this.arcadeTarget.appendChild(newPacman)
      this.extraPacmans.push(newPacman)
    }
  }

  // Get pacman element by index (0 = original, 1+ = extras)
  getPacmanElement(index) {
    if (index === 0) {
      return this.pacmanTarget
    }
    return this.extraPacmans[index - 1]
  }

  async attackWithPacman(victim, pacmanIndex) {
    const pacman = this.getPacmanElement(pacmanIndex)

    // Get victim's position for pacman targeting
    const victimRect = victim.getBoundingClientRect()
    const arcadeRect = this.arcadeTarget.getBoundingClientRect()
    const targetX = victimRect.left - arcadeRect.left + victimRect.width / 2
    const targetY = victimRect.top - arcadeRect.top + victimRect.height / 2

    // Stagger the pacman launches slightly for visual effect
    await this.wait(pacmanIndex * 150)

    // Show and animate pacman moving towards victim
    await this.movePacmanToTarget(pacman, targetX, targetY)

    // Chomp effect
    await this.chompVictim(pacman, victim)
  }

  async movePacmanToTarget(pacman, targetX, targetY) {
    // Show pacman
    pacman.classList.remove('hidden')

    // Position pacman at left edge, same vertical level as victim
    const startX = -100
    const pacmanY = targetY - 40

    pacman.style.left = `${startX}px`
    pacman.style.top = `${pacmanY}px`
    pacman.style.transition = 'none'
    pacman.style.transform = 'scaleX(1)'

    // Force reflow
    pacman.offsetHeight

    // Animate pacman moving to target with chomping animation
    const moveDuration = 1200
    pacman.style.transition = `left ${moveDuration}ms linear`
    pacman.style.left = `${targetX - 40}px`

    // Add chomping class
    pacman.querySelector('.pacman-body').classList.add('pacman-chomping')

    await this.wait(moveDuration)

    return pacman
  }

  async chompVictim(pacman, victim) {
    // Show points at victim's location
    const victimRect = victim.getBoundingClientRect()
    const arcadeRect = this.arcadeTarget.getBoundingClientRect()
    const pointsX = victimRect.left - arcadeRect.left + victimRect.width / 2 - 20
    const pointsY = victimRect.top - arcadeRect.top - 30

    // Create points effect
    const points = document.createElement('div')
    points.className = 'absolute pointer-events-none animate-points-float'
    points.style.left = `${pointsX}px`
    points.style.top = `${pointsY}px`
    points.innerHTML = '<div class="chomp-points text-2xl font-bold text-cyan-300 pacman-font">+100</div>'
    this.arcadeTarget.appendChild(points)

    // Update score
    this.score += 100
    this.scoreValueTarget.textContent = this.score

    // Make victim disappear with classic "eaten" effect
    victim.style.transition = 'all 0.3s ease-out'
    victim.style.transform = 'scale(0)'
    victim.style.opacity = '0'

    await this.wait(300)

    // Remove points
    await this.wait(400)
    points.remove()

    // Remove victim from DOM
    victim.remove()

    // Move pacman off screen to the right
    const arcadeWidth = this.arcadeTarget.getBoundingClientRect().width

    pacman.style.transition = 'left 0.6s linear'
    pacman.style.left = `${arcadeWidth + 100}px`

    await this.wait(600)

    // Hide pacman and stop chomping for next round
    pacman.classList.add('hidden')
    pacman.querySelector('.pacman-body').classList.remove('pacman-chomping')
  }

  showWinner(winnerGhost) {
    const winnerName = winnerGhost.dataset.userName

    // Hide remaining ghost
    winnerGhost.style.transition = 'all 0.5s ease-out'
    winnerGhost.style.transform = 'translateY(-50px) scale(1.2)'

    // Wait a moment then show winner announcement
    setTimeout(() => {
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
    }, 1500)
  }

  wait(ms) {
    return new Promise(resolve => setTimeout(resolve, ms))
  }
}
