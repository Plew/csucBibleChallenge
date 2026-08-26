import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "toggle",
    "testButton",
    "statusMessage",
    "iosNotice"
  ]

  async connect() {
    const isIOS = /iPad|iPhone|iPod/.test(navigator.userAgent) && !window.MSStream
    const isStandalone = window.matchMedia("(display-mode: standalone)").matches || window.navigator.standalone === true

    // On iOS outside standalone mode, Web Push is not supported by Apple
    if (isIOS && !isStandalone) {
      if (this.hasIosNoticeTarget) {
        this.iosNoticeTarget.classList.remove("hidden")
      }
      if (this.hasToggleTarget) {
        this.toggleTarget.disabled = true
      }
      if (this.hasTestButtonTarget) {
        this.testButtonTarget.classList.add("hidden")
      }
      return
    }

    if (!("serviceWorker" in navigator) || !("PushManager" in window)) {
      if (this.hasStatusMessageTarget) {
        this.statusMessageTarget.textContent = "Push notifications are not supported on this browser."
      }
      if (this.hasToggleTarget) {
        this.toggleTarget.disabled = true
      }
      return
    }

    try {
      const registration = await navigator.serviceWorker.ready
      const subscription = await registration.pushManager.getSubscription()

      if (subscription) {
        if (this.hasToggleTarget) {
          this.toggleTarget.checked = true
        }
        // Auto-sync subscription to current logged-in user in Rails DB
        await this.syncSubscription(subscription)
      }
    } catch (e) {
      console.warn("Could not check push subscription:", e)
    }
  }

  async toggle() {
    if (this.toggleTarget.checked) {
      await this.subscribe()
    } else {
      await this.unsubscribe()
    }
  }

  async syncSubscription(subscription) {
    try {
      const json = subscription.toJSON()
      const csrfMeta = document.querySelector('meta[name="csrf-token"]')
      const csrfToken = csrfMeta ? csrfMeta.content : ""

      await fetch("/push_subscriptions", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": csrfToken
        },
        body: JSON.stringify({
          endpoint: json.endpoint,
          p256dh_key: json.keys?.p256dh,
          auth_key: json.keys?.auth
        })
      })
    } catch (e) {
      console.warn("Failed to sync subscription with server:", e)
    }
  }

  async subscribe() {
    try {
      if (this.hasStatusMessageTarget) {
        this.statusMessageTarget.textContent = "Requesting notification permission..."
      }

      const permission = await Notification.requestPermission()
      if (permission !== "granted") {
        if (this.hasToggleTarget) this.toggleTarget.checked = false
        if (this.hasStatusMessageTarget) {
          this.statusMessageTarget.textContent = "Notification permission was denied in browser/device settings."
        }
        return null
      }

      const registration = await navigator.serviceWorker.ready
      const vapidMeta = document.querySelector('meta[name="vapid-public-key"]')
      const vapidPublicKey = vapidMeta ? vapidMeta.content : ""

      if (!vapidPublicKey) {
        throw new Error("VAPID public key not configured on server.")
      }

      let subscription = await registration.pushManager.getSubscription()
      if (!subscription) {
        subscription = await registration.pushManager.subscribe({
          userVisibleOnly: true,
          applicationServerKey: this.urlBase64ToUint8Array(vapidPublicKey)
        })
      }

      await this.syncSubscription(subscription)

      if (this.hasToggleTarget) this.toggleTarget.checked = true
      if (this.hasStatusMessageTarget) {
        this.statusMessageTarget.textContent = "Notifications enabled successfully!"
        setTimeout(() => {
          if (this.hasStatusMessageTarget && this.statusMessageTarget.textContent.includes("successfully")) {
            this.statusMessageTarget.textContent = ""
          }
        }, 4000)
      }

      return subscription
    } catch (error) {
      console.error("Failed to subscribe to push notifications:", error)
      if (this.hasToggleTarget) this.toggleTarget.checked = false
      if (this.hasStatusMessageTarget) {
        this.statusMessageTarget.textContent = "Error: " + error.message
      }
      return null
    }
  }

  async unsubscribe() {
    try {
      const registration = await navigator.serviceWorker.ready
      const subscription = await registration.pushManager.getSubscription()

      if (subscription) {
        const endpoint = subscription.endpoint
        await subscription.unsubscribe()

        const csrfMeta = document.querySelector('meta[name="csrf-token"]')
        const csrfToken = csrfMeta ? csrfMeta.content : ""

        await fetch("/push_subscriptions", {
          method: "DELETE",
          headers: {
            "Content-Type": "application/json",
            "X-CSRF-Token": csrfToken
          },
          body: JSON.stringify({ endpoint: endpoint })
        })
      }

      if (this.hasToggleTarget) this.toggleTarget.checked = false
      if (this.hasStatusMessageTarget) {
        this.statusMessageTarget.textContent = "Notifications disabled."
        setTimeout(() => {
          if (this.hasStatusMessageTarget && this.statusMessageTarget.textContent.includes("disabled")) {
            this.statusMessageTarget.textContent = ""
          }
        }, 3000)
      }
    } catch (error) {
      console.error("Failed to unsubscribe:", error)
    }
  }

  async sendTestPush() {
    if (this.hasTestButtonTarget) {
      this.testButtonTarget.disabled = true
      this.testButtonTarget.textContent = "Sending test..."
    }

    if (this.hasStatusMessageTarget) {
      this.statusMessageTarget.textContent = "Verifying device subscription..."
    }

    try {
      const registration = await navigator.serviceWorker.ready
      let subscription = await registration.pushManager.getSubscription()

      // If not yet subscribed, automatically subscribe first
      if (!subscription) {
        subscription = await this.subscribe()
        if (!subscription) {
          throw new Error("Could not subscribe device for notifications.")
        }
      } else {
        await this.syncSubscription(subscription)
      }

      const csrfMeta = document.querySelector('meta[name="csrf-token"]')
      const csrfToken = csrfMeta ? csrfMeta.content : ""

      const response = await fetch("/push_subscriptions/test", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": csrfToken
        }
      })

      const data = await response.json()

      if (response.ok && data.success) {
        if (this.hasStatusMessageTarget) {
          this.statusMessageTarget.textContent = "🔔 Test notification sent! Check your device notification bar."
        }
      } else {
        if (this.hasStatusMessageTarget) {
          this.statusMessageTarget.textContent = "⚠️ " + (data.error || "Failed to deliver test notification.")
        }
      }
    } catch (error) {
      console.error("Error sending test push:", error)
      if (this.hasStatusMessageTarget) {
        this.statusMessageTarget.textContent = "⚠️ " + error.message
      }
    } finally {
      if (this.hasTestButtonTarget) {
        this.testButtonTarget.disabled = false
        this.testButtonTarget.textContent = "Send Test Notification"
      }
    }
  }

  urlBase64ToUint8Array(base64String) {
    const padding = "=".repeat((4 - (base64String.length % 4)) % 4)
    const base64 = (base64String + padding).replace(/-/g, "+").replace(/_/g, "/")
    const rawData = window.atob(base64)
    const outputArray = new Uint8Array(rawData.length)
    for (let i = 0; i < rawData.length; ++i) {
      outputArray[i] = rawData.charCodeAt(i)
    }
    return outputArray
  }
}
