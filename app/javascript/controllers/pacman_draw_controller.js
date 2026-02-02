import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "startButton",
    "arcade",
    "mazeCanvas",
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
    this.ghostStates = new Map()
    this.animationFrameId = null

    // Maze configuration
    this.cellSize = 40
    this.ghostSize = 60

    // Generate and render maze
    this.generateMaze()
    this.renderMaze()
    this.initializeGhosts()
    this.startGhostMovement()
  }

  disconnect() {
    if (this.animationFrameId) {
      cancelAnimationFrame(this.animationFrameId)
    }
  }

  // Generate a random maze using recursive backtracking
  generateMaze() {
    const arcadeRect = this.arcadeTarget.getBoundingClientRect()
    this.mazeWidth = Math.floor(arcadeRect.width / this.cellSize)
    this.mazeHeight = Math.floor((arcadeRect.height - 120) / this.cellSize) // Leave space for header

    // Ensure odd dimensions for proper maze generation
    if (this.mazeWidth % 2 === 0) this.mazeWidth--
    if (this.mazeHeight % 2 === 0) this.mazeHeight--

    // Minimum size
    this.mazeWidth = Math.max(11, this.mazeWidth)
    this.mazeHeight = Math.max(11, this.mazeHeight)

    // Initialize maze with all walls
    this.maze = []
    for (let y = 0; y < this.mazeHeight; y++) {
      this.maze[y] = []
      for (let x = 0; x < this.mazeWidth; x++) {
        this.maze[y][x] = 1 // 1 = wall, 0 = path
      }
    }

    // Recursive backtracking maze generation
    const stack = []
    const startX = 1
    const startY = 1
    this.maze[startY][startX] = 0
    stack.push({ x: startX, y: startY })

    while (stack.length > 0) {
      const current = stack[stack.length - 1]
      const neighbors = this.getUnvisitedNeighbors(current.x, current.y)

      if (neighbors.length === 0) {
        stack.pop()
      } else {
        const next = neighbors[Math.floor(Math.random() * neighbors.length)]
        // Remove wall between current and next
        const wallX = current.x + (next.x - current.x) / 2
        const wallY = current.y + (next.y - current.y) / 2
        this.maze[wallY][wallX] = 0
        this.maze[next.y][next.x] = 0
        stack.push(next)
      }
    }

    // Add some extra paths to make the maze less restrictive
    this.addExtraPaths()
  }

  getUnvisitedNeighbors(x, y) {
    const neighbors = []
    const directions = [
      { dx: 0, dy: -2 }, // up
      { dx: 2, dy: 0 },  // right
      { dx: 0, dy: 2 },  // down
      { dx: -2, dy: 0 }  // left
    ]

    for (const dir of directions) {
      const nx = x + dir.dx
      const ny = y + dir.dy
      if (nx > 0 && nx < this.mazeWidth - 1 && ny > 0 && ny < this.mazeHeight - 1) {
        if (this.maze[ny][nx] === 1) {
          neighbors.push({ x: nx, y: ny })
        }
      }
    }

    return neighbors
  }

  // Add extra paths to make maze more open
  addExtraPaths() {
    const extraPathCount = Math.floor((this.mazeWidth * this.mazeHeight) / 20)
    for (let i = 0; i < extraPathCount; i++) {
      const x = Math.floor(Math.random() * (this.mazeWidth - 2)) + 1
      const y = Math.floor(Math.random() * (this.mazeHeight - 2)) + 1
      if (this.maze[y][x] === 1) {
        // Check if removing this wall connects two paths
        const adjacentPaths = this.countAdjacentPaths(x, y)
        if (adjacentPaths >= 2) {
          this.maze[y][x] = 0
        }
      }
    }
  }

  countAdjacentPaths(x, y) {
    let count = 0
    const directions = [ { dx: 0, dy: -1 }, { dx: 1, dy: 0 }, { dx: 0, dy: 1 }, { dx: -1, dy: 0 } ]
    for (const dir of directions) {
      const nx = x + dir.dx
      const ny = y + dir.dy
      if (nx >= 0 && nx < this.mazeWidth && ny >= 0 && ny < this.mazeHeight) {
        if (this.maze[ny][nx] === 0) count++
      }
    }
    return count
  }

  renderMaze() {
    const canvas = this.mazeCanvasTarget
    const ctx = canvas.getContext('2d')

    // Set canvas size
    canvas.width = this.mazeWidth * this.cellSize
    canvas.height = this.mazeHeight * this.cellSize

    // Clear canvas
    ctx.fillStyle = '#000033'
    ctx.fillRect(0, 0, canvas.width, canvas.height)

    // Draw walls
    ctx.fillStyle = '#1a1a8c'
    ctx.strokeStyle = '#3333ff'
    ctx.lineWidth = 2

    for (let y = 0; y < this.mazeHeight; y++) {
      for (let x = 0; x < this.mazeWidth; x++) {
        if (this.maze[y][x] === 1) {
          const px = x * this.cellSize
          const py = y * this.cellSize
          ctx.fillRect(px, py, this.cellSize, this.cellSize)
          ctx.strokeRect(px + 1, py + 1, this.cellSize - 2, this.cellSize - 2)
        }
      }
    }

    // Draw dots on paths
    ctx.fillStyle = '#ffff00'
    for (let y = 0; y < this.mazeHeight; y++) {
      for (let x = 0; x < this.mazeWidth; x++) {
        if (this.maze[y][x] === 0) {
          const px = x * this.cellSize + this.cellSize / 2
          const py = y * this.cellSize + this.cellSize / 2
          ctx.beginPath()
          ctx.arc(px, py, 3, 0, Math.PI * 2)
          ctx.fill()
        }
      }
    }
  }

  // Get all path cells (non-wall cells)
  getPathCells() {
    const paths = []
    for (let y = 1; y < this.mazeHeight - 1; y++) {
      for (let x = 1; x < this.mazeWidth - 1; x++) {
        if (this.maze[y][x] === 0) {
          paths.push({ x, y })
        }
      }
    }
    return paths
  }

  initializeGhosts() {
    const paths = this.getPathCells()
    const usedPositions = new Set()

    this.ghostTargets.forEach((ghost) => {
      // Find a random unoccupied path cell
      let cell
      let attempts = 0
      do {
        cell = paths[Math.floor(Math.random() * paths.length)]
        attempts++
      } while (usedPositions.has(`${cell.x},${cell.y}`) && attempts < 100)

      usedPositions.add(`${cell.x},${cell.y}`)

      // Convert cell position to pixel position
      const pixelX = cell.x * this.cellSize + (this.cellSize - this.ghostSize) / 2
      const pixelY = cell.y * this.cellSize + (this.cellSize - this.ghostSize) / 2 + 120 // Offset for header

      // Position the ghost
      ghost.style.position = 'absolute'
      ghost.style.left = `${pixelX}px`
      ghost.style.top = `${pixelY}px`
      ghost.style.transition = 'none'

      // Initialize ghost state with random direction
      const directions = [ 'up', 'down', 'left', 'right' ]
      const validDirs = this.getValidDirections(cell.x, cell.y)
      const direction = validDirs.length > 0
        ? validDirs[Math.floor(Math.random() * validDirs.length)]
        : directions[Math.floor(Math.random() * directions.length)]

      this.ghostStates.set(ghost, {
        cellX: cell.x,
        cellY: cell.y,
        pixelX: pixelX,
        pixelY: pixelY,
        direction: direction,
        speed: 1 + Math.random() * 0.5 // Slightly varied speeds
      })
    })
  }

  getValidDirections(cellX, cellY) {
    const directions = []
    if (cellY > 0 && this.maze[cellY - 1][cellX] === 0) directions.push('up')
    if (cellY < this.mazeHeight - 1 && this.maze[cellY + 1][cellX] === 0) directions.push('down')
    if (cellX > 0 && this.maze[cellY][cellX - 1] === 0) directions.push('left')
    if (cellX < this.mazeWidth - 1 && this.maze[cellY][cellX + 1] === 0) directions.push('right')
    return directions
  }

  startGhostMovement() {
    const moveGhosts = () => {
      this.remainingGhosts.forEach(ghost => {
        if (!this.ghostStates.has(ghost)) return

        const state = this.ghostStates.get(ghost)
        const speed = state.speed

        // Calculate target position based on direction
        let targetX = state.pixelX
        let targetY = state.pixelY

        switch (state.direction) {
          case 'up': targetY -= speed; break
          case 'down': targetY += speed; break
          case 'left': targetX -= speed; break
          case 'right': targetX += speed; break
        }

        // Calculate which cell we'd be in
        const centerX = targetX + this.ghostSize / 2
        const centerY = targetY - 120 + this.ghostSize / 2 // Remove header offset for cell calculation
        const newCellX = Math.floor(centerX / this.cellSize)
        const newCellY = Math.floor(centerY / this.cellSize)

        // Check if we can move to the target position
        const canMove = this.canMoveTo(newCellX, newCellY, state.direction, state.cellX, state.cellY)

        if (canMove) {
          state.pixelX = targetX
          state.pixelY = targetY
          state.cellX = newCellX
          state.cellY = newCellY

          ghost.style.left = `${targetX}px`
          ghost.style.top = `${targetY}px`

          // At intersections, sometimes change direction randomly
          const validDirs = this.getValidDirections(newCellX, newCellY)
          if (validDirs.length > 2 && Math.random() < 0.02) {
            // Filter out opposite direction for more natural movement
            const opposite = this.getOppositeDirection(state.direction)
            const choices = validDirs.filter(d => d !== opposite)
            if (choices.length > 0) {
              state.direction = choices[Math.floor(Math.random() * choices.length)]
            }
          }
        } else {
          // Hit a wall - choose a new random direction
          const validDirs = this.getValidDirections(state.cellX, state.cellY)
          if (validDirs.length > 0) {
            // Prefer not going back the way we came
            const opposite = this.getOppositeDirection(state.direction)
            const preferredDirs = validDirs.filter(d => d !== opposite)
            const choices = preferredDirs.length > 0 ? preferredDirs : validDirs
            state.direction = choices[Math.floor(Math.random() * choices.length)]
          }
        }
      })

      this.animationFrameId = requestAnimationFrame(moveGhosts)
    }

    this.animationFrameId = requestAnimationFrame(moveGhosts)
  }

  canMoveTo(cellX, cellY, direction, fromCellX, fromCellY) {
    // Check bounds
    if (cellX < 0 || cellX >= this.mazeWidth || cellY < 0 || cellY >= this.mazeHeight) {
      return false
    }

    // Check if target cell is a path
    if (this.maze[cellY][cellX] === 1) {
      return false
    }

    return true
  }

  getOppositeDirection(direction) {
    const opposites = { up: 'down', down: 'up', left: 'right', right: 'left' }
    return opposites[direction]
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
      this.ghostStates.delete(victim)
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

    // Get victim's current position (it's moving!)
    const state = this.ghostStates.get(victim)
    const targetX = state ? state.pixelX + this.ghostSize / 2 : parseFloat(victim.style.left) + this.ghostSize / 2
    const targetY = state ? state.pixelY + this.ghostSize / 2 : parseFloat(victim.style.top) + this.ghostSize / 2

    // Stagger the pacman launches slightly for visual effect
    await this.wait(pacmanIndex * 150)

    // Show and animate pacman moving towards victim
    await this.movePacmanToTarget(pacman, targetX, targetY, victim)

    // Chomp effect
    await this.chompVictim(pacman, victim)
  }

  async movePacmanToTarget(pacman, initialTargetX, initialTargetY, victim) {
    // Show pacman
    pacman.classList.remove('hidden')

    // Position pacman at left edge
    const startX = -100
    const startY = initialTargetY - 40

    pacman.style.left = `${startX}px`
    pacman.style.top = `${startY}px`
    pacman.style.transition = 'none'
    pacman.style.transform = 'scaleX(1)'

    // Force reflow
    pacman.offsetHeight

    // Add chomping class
    pacman.querySelector('.pacman-body').classList.add('pacman-chomping')

    // Animate towards the moving ghost
    const moveDuration = 1200
    const startTime = Date.now()

    return new Promise(resolve => {
      const animate = () => {
        const elapsed = Date.now() - startTime
        const progress = Math.min(elapsed / moveDuration, 1)

        // Get current victim position
        const state = this.ghostStates.get(victim)
        const currentTargetX = state ? state.pixelX + this.ghostSize / 2 : parseFloat(victim.style.left) + this.ghostSize / 2
        const currentTargetY = state ? state.pixelY + this.ghostSize / 2 : parseFloat(victim.style.top) + this.ghostSize / 2

        // Interpolate pacman position towards current target
        const pacmanX = startX + (currentTargetX - 40 - startX) * progress
        const pacmanY = startY + (currentTargetY - 40 - startY) * progress

        pacman.style.left = `${pacmanX}px`
        pacman.style.top = `${pacmanY}px`

        if (progress < 1) {
          requestAnimationFrame(animate)
        } else {
          resolve(pacman)
        }
      }
      requestAnimationFrame(animate)
    })
  }

  async chompVictim(pacman, victim) {
    // Get victim's current position
    const state = this.ghostStates.get(victim)
    const victimX = state ? state.pixelX : parseFloat(victim.style.left)
    const victimY = state ? state.pixelY : parseFloat(victim.style.top)

    // Create points effect
    const points = document.createElement('div')
    points.className = 'absolute pointer-events-none animate-points-float'
    points.style.left = `${victimX}px`
    points.style.top = `${victimY - 30}px`
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
    // Stop ghost movement
    if (this.animationFrameId) {
      cancelAnimationFrame(this.animationFrameId)
    }

    const winnerName = winnerGhost.dataset.userName

    // Animate winner ghost
    winnerGhost.style.transition = 'all 0.5s ease-out'
    winnerGhost.style.transform = 'scale(1.5)'
    winnerGhost.style.zIndex = '100'

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
