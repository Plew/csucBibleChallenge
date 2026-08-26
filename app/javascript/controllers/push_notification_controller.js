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
      return
    }

    if (!("serviceWorker" in navigator) || !("PushManager" in window)) {
      if (this.hasStatusMessageTarget) {
        this.statusMessageTarget.textContent = "Push notifications are not supported on this browser."
      }
      return
    }

    const registration = await navigator.serviceWorker.ready
    const subscription = await registration.pushManager.getSubscription()

    if (subscription) {
      this.toggleTarget.checked = true
      if (this.hasTestButtonTarget) {
        this.testButtonTarget.classList.remove("hidden")
      }
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
        this.toggleTarget.checked = false
        if (this.hasStatusMessageTarget) {
          this.statusMessageTarget.textContent = "Notification permission was not granted."
        }
        return
      }

      const registration = await navigator.serviceWorker.ready
      const vapidMeta = document.querySelector('meta[name="vapid-public-key"]')
      const vapidPublicKey = vapidMeta ? vapidMeta.content : ""

      if (!vapidPublicKey) {
        console.warn("VAPID public key not found in meta tag")
        return
      }

      const subscription = await registration.pushManager.subscribe({
        userVisibleOnly: true,
        applicationServerKey: this.urlBase64ToUint8Array(vapidPublicKey)
      })

      const json = subscription.toJSON()
      const csrfMeta = document.querySelector('meta[name="csrf-token"]')
      const csrfToken = csrfMeta ? csrfMeta.content : ""

      const response = await fetch("/push_subscriptions", {
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

      if (response.ok) {
        this.toggleTarget.checked = true
        if (this.hasTestButtonTarget) {
          this.testButtonTarget.classList.remove("hidden")
        }
        if (this.hasStatusMessageTarget) {
          this.statusMessageTarget.textContent = "Notifications enabled successfully!"
          setTimeout(() => {
            if (this.hasStatusMessageTarget) this.statusMessageTarget.textContent = ""
          }, 4000)
        }
      }
    } catch (error) {
      console.error("Failed to subscribe to push notifications:", error)
      this.toggleTarget.checked = false
      if (this.hasStatusMessageTarget) {
        this.statusMessageTarget.textContent = "Error: " + error.message
      }
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

      this.toggleTarget.checked = false
      if (this.hasTestButtonTarget) {
        this.testButtonTarget.classList.add("hidden")
      }
      if (this.hasStatusMessageTarget) {
        this.statusMessageTarget.textContent = "Notifications disabled."
        setTimeout(() => {
          if (this.hasStatusMessageTarget) this.statusMessageTarget.textContent = ""
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

    try {
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
          this.statusMessageTarget.textContent = "🔔 Test push notification sent! Check your notification center."
        }
      } else {
        if (this.hasStatusMessageTarget) {
          this.statusMessageTarget.textContent = data.error || "Failed to send test push."
        }
      }
    } catch (error) {
      console.error("Error sending test push:", error)
      if (this.hasStatusMessageTarget) {
        this.statusMessageTarget.textContent = "Error sending test push: " + error.message
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
