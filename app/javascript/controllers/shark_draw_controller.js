import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "startButton",
    "ocean",
    "swimmersContainer",
    "swimmer",
    "shark",
    "splash",
    "chompOverlay",
    "chompText",
    "lifeRaft",
    "winnerAvatar",
    "winnerAnnouncement",
    "winnerName",
    "waveLine"
  ]

  connect() {
    this.isRunning = false
    this.remainingSwimmers = [...this.swimmerTargets]
    this.chompCycleTime = 3500 // Time for each elimination cycle
    this.extraSharks = [] // Store dynamically created shark elements
  }

  startHunt() {
    if (this.isRunning) return

    this.isRunning = true
    this.startButtonTarget.disabled = true
    this.startButtonTarget.classList.add('hidden')

    // Start the elimination sequence
    this.eliminateNext()
  }

  // Calculate how many sharks should attack this round
  getSharkCount() {
    const swimmerCount = this.remainingSwimmers.length
    // 1 shark per 5 swimmers, minimum 1
    return Math.max(1, Math.floor(swimmerCount / 5))
  }

  async eliminateNext() {
    // Check if we have a winner (only one swimmer left)
    if (this.remainingSwimmers.length === 1) {
      await this.wait(500)
      this.showWinner(this.remainingSwimmers[0])
      return
    }

    const sharkCount = this.getSharkCount()
    // Don't eliminate more swimmers than we have (minus 1 for the winner)
    const victimsToEliminate = Math.min(sharkCount, this.remainingSwimmers.length - 1)

    // Pick random swimmers to eliminate
    const victims = []
    const availableSwimmers = [...this.remainingSwimmers]
    for (let i = 0; i < victimsToEliminate; i++) {
      const victimIndex = Math.floor(Math.random() * availableSwimmers.length)
      victims.push(availableSwimmers[victimIndex])
      availableSwimmers.splice(victimIndex, 1)
    }

    // Make non-victim swimmers "nervous" - shake slightly
    this.remainingSwimmers.forEach(swimmer => {
      if (!victims.includes(swimmer)) {
        swimmer.classList.add('animate-nervous')
      }
    })

    // Ensure we have enough shark elements
    this.ensureSharkElements(victimsToEliminate)

    // Launch all sharks simultaneously towards their victims
    const sharkPromises = victims.map((victim, index) => {
      return this.attackWithShark(victim, index)
    })

    // Wait for all sharks to complete their attacks
    await Promise.all(sharkPromises)

    // Remove victims from remaining swimmers
    victims.forEach(victim => {
      this.remainingSwimmers = this.remainingSwimmers.filter(s => s !== victim)
    })

    // Remove nervous animation
    this.remainingSwimmers.forEach(swimmer => {
      swimmer.classList.remove('animate-nervous')
    })

    // Wait before next round
    await this.wait(800)

    // Continue elimination
    this.eliminateNext()
  }

  // Ensure we have enough shark elements for the attack
  ensureSharkElements(count) {
    // We already have one shark from the template
    const existingCount = 1 + this.extraSharks.length

    for (let i = existingCount; i < count; i++) {
      const newShark = document.createElement('div')
      newShark.className = 'absolute hidden'
      newShark.style.top = '50%'
      newShark.style.left = '-150px'
      newShark.innerHTML = '<div class="shark-body text-8xl"><span class="inline-block">🦈</span></div>'
      this.oceanTarget.appendChild(newShark)
      this.extraSharks.push(newShark)
    }
  }

  // Get shark element by index (0 = original, 1+ = extras)
  getSharkElement(index) {
    if (index === 0) {
      return this.sharkTarget
    }
    return this.extraSharks[index - 1]
  }

  async attackWithShark(victim, sharkIndex) {
    const shark = this.getSharkElement(sharkIndex)

    // Get victim's position for shark targeting
    const victimRect = victim.getBoundingClientRect()
    const oceanRect = this.oceanTarget.getBoundingClientRect()
    const targetX = victimRect.left - oceanRect.left + victimRect.width / 2
    const targetY = victimRect.top - oceanRect.top + victimRect.height / 2

    // Stagger the shark launches slightly for visual effect
    await this.wait(sharkIndex * 150)

    // Show and animate shark swimming towards victim
    await this.swimSharkToTargetElement(shark, targetX, targetY)

    // Chomp effect
    await this.chompVictim(shark, victim)
  }

  async swimSharkToTargetElement(shark, targetX, targetY) {
    // Show shark
    shark.classList.remove('hidden')

    // Position shark at left edge, same vertical level as victim
    const startX = -150
    const sharkY = targetY - 40 // Adjust for shark size

    shark.style.left = `${startX}px`
    shark.style.top = `${sharkY}px`
    shark.style.transition = 'none'
    shark.style.transform = 'scaleX(1)'

    // Force reflow
    shark.offsetHeight

    // Animate shark swimming to target
    const swimDuration = 1500
    shark.style.transition = `left ${swimDuration}ms ease-in-out`
    shark.style.left = `${targetX - 50}px`

    await this.wait(swimDuration)

    return shark
  }

  async chompVictim(shark, victim) {
    // Show splash at victim's location
    const victimRect = victim.getBoundingClientRect()
    const oceanRect = this.oceanTarget.getBoundingClientRect()
    const splashX = victimRect.left - oceanRect.left + victimRect.width / 2 - 30
    const splashY = victimRect.top - oceanRect.top - 20

    // Create a splash element for this victim
    const splash = document.createElement('div')
    splash.className = 'absolute pointer-events-none animate-splash'
    splash.style.left = `${splashX}px`
    splash.style.top = `${splashY}px`
    splash.innerHTML = '<div class="splash-effect text-6xl">💦</div>'
    this.oceanTarget.appendChild(splash)

    // Make victim disappear with dramatic effect
    victim.style.transition = 'all 0.3s ease-out'
    victim.style.transform = 'scale(0) rotate(180deg)'
    victim.style.opacity = '0'

    await this.wait(300)

    // Remove splash
    await this.wait(200)
    splash.remove()

    // Remove victim from DOM
    victim.remove()

    // Swim shark off screen to the right
    const oceanWidth = this.oceanTarget.getBoundingClientRect().width

    shark.style.transition = 'left 0.8s ease-in-out'
    shark.style.left = `${oceanWidth + 150}px`

    await this.wait(800)

    // Hide shark for next round
    shark.classList.add('hidden')
  }

  showWinner(winnerSwimmer) {
    const winnerName = winnerSwimmer.dataset.userName

    // Hide remaining swimmer
    winnerSwimmer.style.transition = 'all 0.5s ease-out'
    winnerSwimmer.style.transform = 'translateY(-50px)'
    winnerSwimmer.style.opacity = '0'

    // Show life raft with winner
    const avatarHtml = winnerSwimmer.querySelector('img').outerHTML
    this.winnerAvatarTarget.innerHTML = avatarHtml

    // Position and show life raft
    this.lifeRaftTarget.classList.remove('hidden')
    this.lifeRaftTarget.classList.add('animate-celebration')

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
    }, 2000)
  }

  wait(ms) {
    return new Promise(resolve => setTimeout(resolve, ms))
  }
}
