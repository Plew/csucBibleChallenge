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
    this.ghostStates = new Map()
    this.animationFrameId = null
    this.pacmanState = null

    // Maze configuration
    this.cellSize = 40
    this.ghostSize = 60
    this.pacmanSize = 80

    // Speed configuration - Pac-Man is faster than ghosts
    this.ghostBaseSpeed = 1.2
    this.pacmanSpeed = 2.0

    // Generate and render maze
    this.generateMaze()
    this.renderMaze()
    this.initializeGhosts()
    this.initializePacman()
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
    this.mazeHeight = Math.floor((arcadeRect.height - 120) / this.cellSize)

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
        this.maze[y][x] = 1
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
        const wallX = current.x + (next.x - current.x) / 2
        const wallY = current.y + (next.y - current.y) / 2
        this.maze[wallY][wallX] = 0
        this.maze[next.y][next.x] = 0
        stack.push(next)
      }
    }

    this.addExtraPaths()
  }

  getUnvisitedNeighbors(x, y) {
    const neighbors = []
    const directions = [
      { dx: 0, dy: -2 },
      { dx: 2, dy: 0 },
      { dx: 0, dy: 2 },
      { dx: -2, dy: 0 }
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

  addExtraPaths() {
    const extraPathCount = Math.floor((this.mazeWidth * this.mazeHeight) / 15)
    for (let i = 0; i < extraPathCount; i++) {
      const x = Math.floor(Math.random() * (this.mazeWidth - 2)) + 1
      const y = Math.floor(Math.random() * (this.mazeHeight - 2)) + 1
      if (this.maze[y][x] === 1) {
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

    canvas.width = this.mazeWidth * this.cellSize
    canvas.height = this.mazeHeight * this.cellSize

    ctx.fillStyle = '#000033'
    ctx.fillRect(0, 0, canvas.width, canvas.height)

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
      let cell
      let attempts = 0
      do {
        cell = paths[Math.floor(Math.random() * paths.length)]
        attempts++
      } while (usedPositions.has(`${cell.x},${cell.y}`) && attempts < 100)

      usedPositions.add(`${cell.x},${cell.y}`)

      const pixelX = cell.x * this.cellSize + (this.cellSize - this.ghostSize) / 2
      const pixelY = cell.y * this.cellSize + (this.cellSize - this.ghostSize) / 2 + 120

      ghost.style.position = 'absolute'
      ghost.style.left = `${pixelX}px`
      ghost.style.top = `${pixelY}px`
      ghost.style.transition = 'none'

      const validDirs = this.getValidDirections(cell.x, cell.y)
      const direction = validDirs.length > 0
        ? validDirs[Math.floor(Math.random() * validDirs.length)]
        : 'right'

      this.ghostStates.set(ghost, {
        cellX: cell.x,
        cellY: cell.y,
        pixelX: pixelX,
        pixelY: pixelY,
        direction: direction,
        speed: this.ghostBaseSpeed + Math.random() * 0.3
      })
    })
  }

  initializePacman() {
    const paths = this.getPathCells()
    // Start Pac-Man at a random position
    const cell = paths[Math.floor(Math.random() * paths.length)]

    const pixelX = cell.x * this.cellSize + (this.cellSize - this.pacmanSize) / 2
    const pixelY = cell.y * this.cellSize + (this.cellSize - this.pacmanSize) / 2 + 120

    const pacman = this.pacmanTarget
    pacman.style.position = 'absolute'
    pacman.style.left = `${pixelX}px`
    pacman.style.top = `${pixelY}px`
    pacman.style.transition = 'none'
    pacman.classList.add('hidden')

    const validDirs = this.getValidDirections(cell.x, cell.y)
    const direction = validDirs.length > 0
      ? validDirs[Math.floor(Math.random() * validDirs.length)]
      : 'right'

    this.pacmanState = {
      cellX: cell.x,
      cellY: cell.y,
      pixelX: pixelX,
      pixelY: pixelY,
      direction: direction,
      speed: this.pacmanSpeed
    }
  }

  getValidDirections(cellX, cellY) {
    const directions = []
    if (cellY > 0 && this.maze[cellY - 1][cellX] === 0) directions.push('up')
    if (cellY < this.mazeHeight - 1 && this.maze[cellY + 1][cellX] === 0) directions.push('down')
    if (cellX > 0 && this.maze[cellY][cellX - 1] === 0) directions.push('left')
    if (cellX < this.mazeWidth - 1 && this.maze[cellY][cellX + 1] === 0) directions.push('right')
    return directions
  }

  startGame() {
    if (this.isRunning) return

    this.isRunning = true
    this.startButtonTarget.disabled = true
    this.startButtonTarget.classList.add('hidden')

    // Show Pac-Man and start chomping
    this.pacmanTarget.classList.remove('hidden')
    this.pacmanTarget.querySelector('.pacman-body').classList.add('pacman-chomping')

    // Show power mode
    this.powerModeTarget.classList.remove('hidden')

    // Start the game loop
    this.startGameLoop()
  }

  startGameLoop() {
    const gameLoop = () => {
      // Check for winner
      if (this.remainingGhosts.length === 1) {
        this.showWinner(this.remainingGhosts[0])
        return
      }

      if (this.remainingGhosts.length === 0) {
        return
      }

      // Move ghosts
      this.moveGhosts()

      // Move Pac-Man towards target
      this.movePacman()

      // Check for collisions
      this.checkCollisions()

      this.animationFrameId = requestAnimationFrame(gameLoop)
    }

    this.animationFrameId = requestAnimationFrame(gameLoop)
  }

  moveGhosts() {
    this.remainingGhosts.forEach(ghost => {
      if (!this.ghostStates.has(ghost)) return

      const state = this.ghostStates.get(ghost)
      const speed = state.speed

      let targetX = state.pixelX
      let targetY = state.pixelY

      switch (state.direction) {
        case 'up': targetY -= speed; break
        case 'down': targetY += speed; break
        case 'left': targetX -= speed; break
        case 'right': targetX += speed; break
      }

      const centerX = targetX + this.ghostSize / 2
      const centerY = targetY - 120 + this.ghostSize / 2
      const newCellX = Math.floor(centerX / this.cellSize)
      const newCellY = Math.floor(centerY / this.cellSize)

      const canMove = this.canMoveTo(newCellX, newCellY)

      if (canMove) {
        state.pixelX = targetX
        state.pixelY = targetY
        state.cellX = newCellX
        state.cellY = newCellY

        ghost.style.left = `${targetX}px`
        ghost.style.top = `${targetY}px`

        const validDirs = this.getValidDirections(newCellX, newCellY)
        if (validDirs.length > 2 && Math.random() < 0.03) {
          const opposite = this.getOppositeDirection(state.direction)
          const choices = validDirs.filter(d => d !== opposite)
          if (choices.length > 0) {
            state.direction = choices[Math.floor(Math.random() * choices.length)]
          }
        }
      } else {
        const validDirs = this.getValidDirections(state.cellX, state.cellY)
        if (validDirs.length > 0) {
          const opposite = this.getOppositeDirection(state.direction)
          const preferredDirs = validDirs.filter(d => d !== opposite)
          const choices = preferredDirs.length > 0 ? preferredDirs : validDirs
          state.direction = choices[Math.floor(Math.random() * choices.length)]
        }
      }
    })
  }

  movePacman() {
    if (!this.pacmanState) return

    const state = this.pacmanState
    const pacman = this.pacmanTarget

    // Calculate target position based on current direction
    let targetX = state.pixelX
    let targetY = state.pixelY

    switch (state.direction) {
      case 'up': targetY -= state.speed; break
      case 'down': targetY += state.speed; break
      case 'left': targetX -= state.speed; break
      case 'right': targetX += state.speed; break
    }

    // Calculate which cell we'd be in
    const centerX = targetX + this.pacmanSize / 2
    const centerY = targetY - 120 + this.pacmanSize / 2
    const newCellX = Math.floor(centerX / this.cellSize)
    const newCellY = Math.floor(centerY / this.cellSize)

    const canMove = this.canMoveTo(newCellX, newCellY)

    if (canMove) {
      state.pixelX = targetX
      state.pixelY = targetY
      state.cellX = newCellX
      state.cellY = newCellY

      pacman.style.left = `${targetX}px`
      pacman.style.top = `${targetY}px`

      // Update Pac-Man rotation based on direction
      this.updatePacmanDirection(pacman, state.direction)

      // At intersections, sometimes change direction randomly
      const validDirs = this.getValidDirections(newCellX, newCellY)
      if (validDirs.length > 2 && Math.random() < 0.03) {
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
  }

  updatePacmanDirection(pacman, direction) {
    let rotation = 0
    switch (direction) {
      case 'right': rotation = 0; break
      case 'down': rotation = 90; break
      case 'left': rotation = 180; break
      case 'up': rotation = 270; break
    }
    pacman.style.transform = `rotate(${rotation}deg)`
  }

  checkCollisions() {
    if (!this.pacmanState) return

    const pacmanCenterX = this.pacmanState.pixelX + this.pacmanSize / 2
    const pacmanCenterY = this.pacmanState.pixelY + this.pacmanSize / 2

    const collisionDistance = (this.pacmanSize + this.ghostSize) / 2 - 15

    for (const ghost of this.remainingGhosts) {
      const ghostState = this.ghostStates.get(ghost)
      if (!ghostState) continue

      const ghostCenterX = ghostState.pixelX + this.ghostSize / 2
      const ghostCenterY = ghostState.pixelY + this.ghostSize / 2

      const dx = pacmanCenterX - ghostCenterX
      const dy = pacmanCenterY - ghostCenterY
      const distance = Math.sqrt(dx * dx + dy * dy)

      if (distance < collisionDistance) {
        this.eliminateGhost(ghost)
        break
      }
    }
  }

  async eliminateGhost(ghost) {
    // Get ghost position for points effect
    const ghostState = this.ghostStates.get(ghost)
    const ghostX = ghostState ? ghostState.pixelX : parseFloat(ghost.style.left)
    const ghostY = ghostState ? ghostState.pixelY : parseFloat(ghost.style.top)

    // Create points effect
    const points = document.createElement('div')
    points.className = 'absolute pointer-events-none animate-points-float z-50'
    points.style.left = `${ghostX}px`
    points.style.top = `${ghostY - 30}px`
    points.innerHTML = '<div class="chomp-points text-2xl font-bold text-cyan-300 pacman-font">+100</div>'
    this.arcadeTarget.appendChild(points)

    // Update score
    this.score += 100
    this.scoreValueTarget.textContent = this.score

    // Increase Pac-Man speed
    this.pacmanState.speed += 0.4

    // Make ghost disappear with eaten effect
    ghost.style.transition = 'all 0.3s ease-out'
    ghost.style.transform = 'scale(0)'
    ghost.style.opacity = '0'

    // Remove ghost from tracking
    this.remainingGhosts = this.remainingGhosts.filter(g => g !== ghost)
    this.ghostStates.delete(ghost)

    // Remove ghost after animation
    setTimeout(() => {
      ghost.remove()
      points.remove()
    }, 500)
  }

  canMoveTo(cellX, cellY) {
    if (cellX < 0 || cellX >= this.mazeWidth || cellY < 0 || cellY >= this.mazeHeight) {
      return false
    }
    if (this.maze[cellY][cellX] === 1) {
      return false
    }
    return true
  }

  getOppositeDirection(direction) {
    const opposites = { up: 'down', down: 'up', left: 'right', right: 'left' }
    return opposites[direction]
  }

  showWinner(winnerGhost) {
    // Stop game loop
    if (this.animationFrameId) {
      cancelAnimationFrame(this.animationFrameId)
    }

    // Hide Pac-Man
    this.pacmanTarget.classList.add('hidden')
    this.powerModeTarget.classList.add('hidden')

    const winnerName = winnerGhost.dataset.userName

    // Animate winner ghost
    winnerGhost.style.transition = 'all 0.5s ease-out'
    winnerGhost.style.transform = 'scale(1.5)'
    winnerGhost.style.zIndex = '100'

    // Show winner announcement
    setTimeout(() => {
      this.winnerNameTarget.textContent = winnerName
      this.winnerAnnouncementTarget.classList.remove('hidden')

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
