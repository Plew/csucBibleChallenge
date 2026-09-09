import { Controller } from "@hotwired/stimulus"
import consumer from "channels/consumer"

// Activity tracking settings (constants)
const INACTIVITY_TIMEOUT = 60000  // 60 seconds until marked inactive
const HEARTBEAT_INTERVAL = 15000  // Send heartbeat every 15 seconds
const INACTIVITY_CHECK_INTERVAL = 5000  // Check for inactivity every 5 seconds

// Tracks user activity on a reading page and reports presence via ActionCable.
// Users are marked inactive after 60 seconds of no scrolling/movement/activity.
const AVATAR_PALETTE = [
  "#6B7558", // Muted Olive (Theme Primary)
  "#C79C46", // Mustard Gold (Theme Secondary / Warning)
  "#4A6B82", // Muted Slate Blue (Theme Info)
  "#B05858", // Terracotta Rust (Theme Error)
  "#556E3F", // Forest Green (Theme Success)
  "#4F5D95", // Dusty Indigo
  "#8B5A7E", // Warm Plum
  "#2E7977", // Deep Teal
  "#BD5A38", // Rust Orange
  "#3D7896", // Soft Ocean Blue
  "#87533E", // Warm Cedar
  "#A8536E", // Dusty Rose
  "#8A6B3D", // Rich Bronze
  "#3E6953", // Forest Pine
  "#38526F", // Slate Navy
  "#7A4B6B"  // Warm Mulberry
]

function getAvatarColor(username) {
  let hash = 5381
  const str = String(username || "")
  for (let i = 0; i < str.length; i++) {
    hash = ((hash << 5) + hash + str.charCodeAt(i)) >>> 0
  }
  return AVATAR_PALETTE[hash % AVATAR_PALETTE.length]
}

export default class extends Controller {
  static targets = [ "avatars", "container" ]
  static values = { readingId: Number }

  connect() {
    this.lastActivity = Date.now()
    this.isActive = true
    this.subscription = null
    this.currentUsers = []

    this.setupActivityTracking()
    this.setupChannel()
    this.startIntervals()
  }

  disconnect() {
    this.cleanupActivityTracking()
    this.stopIntervals()
    this.cleanupChannel()
  }

  setupActivityTracking() {
    // Events that indicate user activity
    this.activityEvents = [
      "scroll",
      "mousemove",
      "click",
      "keypress",
      "touchstart",
      "touchmove"
    ]

    // Bind the handler so we can remove it later
    this.boundRecordActivity = this.recordActivity.bind(this)

    // Add listeners to document
    this.activityEvents.forEach(event => {
      document.addEventListener(event, this.boundRecordActivity, { passive: true })
    })

    // Also track page visibility changes
    this.boundHandleVisibility = this.handleVisibilityChange.bind(this)
    document.addEventListener("visibilitychange", this.boundHandleVisibility)
  }

  cleanupActivityTracking() {
    this.activityEvents.forEach(event => {
      document.removeEventListener(event, this.boundRecordActivity)
    })
    document.removeEventListener("visibilitychange", this.boundHandleVisibility)
  }

  setupChannel() {
    this.subscription = consumer.subscriptions.create(
      { channel: "ReadingPresenceChannel", reading_id: this.readingIdValue },
      {
        received: this.handleReceived.bind(this),
        connected: () => {
          console.log("Connected to reading presence channel")
        },
        disconnected: () => {
          console.log("Disconnected from reading presence channel")
        }
      }
    )
  }

  cleanupChannel() {
    if (this.subscription) {
      this.subscription.unsubscribe()
      this.subscription = null
    }
  }

  startIntervals() {
    // Send heartbeat periodically (if active)
    this.heartbeatInterval = setInterval(() => {
      this.sendHeartbeat()
    }, HEARTBEAT_INTERVAL)

    // Check for inactivity periodically
    this.inactivityCheckInterval = setInterval(() => {
      this.checkInactivity()
    }, INACTIVITY_CHECK_INTERVAL)
  }

  stopIntervals() {
    if (this.heartbeatInterval) {
      clearInterval(this.heartbeatInterval)
    }
    if (this.inactivityCheckInterval) {
      clearInterval(this.inactivityCheckInterval)
    }
  }

  recordActivity() {
    this.lastActivity = Date.now()

    // If was inactive, immediately notify server we're back
    if (!this.isActive) {
      this.isActive = true
      this.sendHeartbeat()
    }
  }

  handleVisibilityChange() {
    if (document.visibilityState === "hidden") {
      // Tab became hidden, mark as inactive
      this.isActive = false
      this.sendInactive()
    } else if (document.visibilityState === "visible") {
      // Tab became visible, record activity
      this.recordActivity()
    }
  }

  checkInactivity() {
    const inactiveFor = Date.now() - this.lastActivity

    if (inactiveFor > INACTIVITY_TIMEOUT && this.isActive) {
      this.isActive = false
      this.sendInactive()
    }
  }

  sendHeartbeat() {
    if (this.isActive && this.subscription) {
      this.subscription.perform("heartbeat")
    }
  }

  sendInactive() {
    if (this.subscription) {
      this.subscription.perform("inactive")
    }
  }

  handleReceived(data) {
    if (data.type === "presence_update") {
      this.updateAvatars(data.users)
    }
  }

  updateAvatars(users) {
    if (!this.hasAvatarsTarget) return

    const container = this.avatarsTarget
    const wrapper = this.hasContainerTarget ? this.containerTarget : container
    const newUserIds = new Set(users.map(u => u.id))
    const existingUserIds = new Set(this.currentUsers.map(u => u.id))

    // Remove avatars for users who left
    this.currentUsers.forEach(user => {
      if (!newUserIds.has(user.id)) {
        const avatar = container.querySelector(`[data-user-id="${user.id}"]`)
        if (avatar) {
          avatar.classList.add("presence-avatar-exit")
          setTimeout(() => avatar.remove(), 200)
        }
      }
    })

    // Add avatars for new users
    users.forEach((user, index) => {
      if (!existingUserIds.has(user.id)) {
        const avatar = this.createAvatarElement(user, index)
        avatar.classList.add("presence-avatar-enter")
        container.appendChild(avatar)
        // Force reflow then remove enter class to trigger transition
        avatar.offsetHeight // Force reflow
        requestAnimationFrame(() => {
          avatar.classList.remove("presence-avatar-enter")
        })
      }
    })

    this.currentUsers = users

    if (users.length === 0) {
      wrapper.classList.add("hidden")
      if (wrapper !== container) container.classList.add("hidden")
    } else {
      wrapper.classList.remove("hidden")
      if (wrapper !== container) container.classList.remove("hidden")
    }
  }

  createAvatarElement(user, index) {
    const wrapper = document.createElement("div")
    wrapper.className = "presence-avatar tooltip tooltip-bottom"
    wrapper.dataset.userId = user.id
    wrapper.dataset.tip = user.username
    wrapper.title = user.username

    const link = document.createElement("a")
    link.href = `/users/${user.id}`
    link.className = "block"

    const img = document.createElement("img")
    img.src = user.avatar_url
    img.alt = user.username
    img.className = "w-7 h-7 rounded-full object-cover ring-2 ring-base-100 shadow-sm hover:ring-primary hover:z-10 transition-all"
    img.onerror = () => {
      // Fallback: generate SVG avatar with user's initial
      img.src = this.generatePlaceholderAvatar(user.username)
    }

    link.appendChild(img)
    wrapper.appendChild(link)
    return wrapper
  }

  generatePlaceholderAvatar(username) {
    const initial = (username || "?")[0].toUpperCase()
    const color = getAvatarColor(username)

    const svg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32">
      <rect width="32" height="32" fill="${color}" rx="16"/>
      <text x="16" y="21" text-anchor="middle" fill="white" font-family="system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif" font-size="14" font-weight="600">${initial}</text>
    </svg>`

    return `data:image/svg+xml;utf8,${encodeURIComponent(svg)}`
  }
}
