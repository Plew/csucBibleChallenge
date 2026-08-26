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

    if (isIOS && !isStandalone) {
      if (this.hasIosNoticeTarget) this.iosNoticeTarget.classList.remove("hidden")
      if (this.hasToggleTarget) this.toggleTarget.disabled = true
      return
    }

    if (!("serviceWorker" in navigator) || !("PushManager" in window)) {
      if (this.hasStatusMessageTarget) {
        this.statusMessageTarget.textContent = "Push notifications are not supported on this browser."
      }
      if (this.hasToggleTarget) this.toggleTarget.disabled = true
      return
    }

    try {
      const registration = await navigator.serviceWorker.ready
      const subscription = await registration.pushManager.getSubscription()

      if (subscription && this.hasToggleTarget) {
        this.toggleTarget.checked = true
      }
    } catch (e) {
      console.warn("Push subscription check error:", e)
    }
  }

  async toggle() {
    if (this.toggleTarget.checked) {
      await this.subscribe()
    } else {
      await this.unsubscribe()
    }
  }

  async subscribe() {
    try {
      const permission = await Notification.requestPermission()
      if (permission !== "granted") {
        if (this.hasToggleTarget) this.toggleTarget.checked = false
        if (this.hasStatusMessageTarget) {
          this.statusMessageTarget.textContent = "Notification permission was denied."
        }
        return null
      }

      const registration = await navigator.serviceWorker.ready
      const vapidPublicKey = document.querySelector('meta[name="vapid-public-key"]')?.content

      if (!vapidPublicKey) {
        throw new Error("VAPID public key not found on page.")
      }

      const subscription = await registration.pushManager.subscribe({
        userVisibleOnly: true,
        applicationServerKey: this.urlBase64ToUint8Array(vapidPublicKey)
      })

      const json = subscription.toJSON()
      const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

      await fetch("/push_subscriptions", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": csrfToken || ""
        },
        body: JSON.stringify({
          endpoint: json.endpoint,
          p256dh_key: json.keys?.p256dh,
          auth_key: json.keys?.auth
        })
      })

      if (this.hasToggleTarget) this.toggleTarget.checked = true
      if (this.hasStatusMessageTarget) {
        this.statusMessageTarget.textContent = "Notifications enabled!"
        setTimeout(() => { if (this.hasStatusMessageTarget) this.statusMessageTarget.textContent = "" }, 3000)
      }

      return subscription
    } catch (error) {
      console.error("Subscribe error:", error)
      if (this.hasToggleTarget) this.toggleTarget.checked = false
      if (this.hasStatusMessageTarget) {
        this.statusMessageTarget.textContent = error.message
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

        const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

        await fetch("/push_subscriptions", {
          method: "DELETE",
          headers: {
            "Content-Type": "application/json",
            "X-CSRF-Token": csrfToken || ""
          },
          body: JSON.stringify({ endpoint: endpoint })
        })
      }

      if (this.hasToggleTarget) this.toggleTarget.checked = false
      if (this.hasStatusMessageTarget) {
        this.statusMessageTarget.textContent = "Notifications disabled."
        setTimeout(() => { if (this.hasStatusMessageTarget) this.statusMessageTarget.textContent = "" }, 3000)
      }
    } catch (error) {
      console.error("Unsubscribe error:", error)
    }
  }

  async sendTestPush() {
    if (this.hasTestButtonTarget) {
      this.testButtonTarget.disabled = true
      this.testButtonTarget.textContent = "Sending..."
    }

    try {
      const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

      const response = await fetch("/push_subscriptions/test", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": csrfToken || ""
        }
      })

      const data = await response.json()

      if (response.ok && data.success) {
        if (this.hasStatusMessageTarget) {
          this.statusMessageTarget.textContent = "🔔 Test push notification sent!"
        }
      } else {
        if (this.hasStatusMessageTarget) {
          this.statusMessageTarget.textContent = data.error || "Failed to send test push."
        }
      }
    } catch (error) {
      if (this.hasStatusMessageTarget) {
        this.statusMessageTarget.textContent = error.message
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
