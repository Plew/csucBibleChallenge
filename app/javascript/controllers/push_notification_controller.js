import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "toggle" ]

  async connect() {
    if (!("serviceWorker" in navigator) || !("PushManager" in window)) {
      this.element.classList.add("hidden")
      return
    }

    const registration = await navigator.serviceWorker.ready
    const subscription = await registration.pushManager.getSubscription()

    if (subscription) {
      this.toggleTarget.checked = true
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
    const permission = await Notification.requestPermission()
    if (permission !== "granted") {
      this.toggleTarget.checked = false
      return
    }

    const registration = await navigator.serviceWorker.ready
    const vapidPublicKey = document.querySelector('meta[name="vapid-public-key"]').content

    const subscription = await registration.pushManager.subscribe({
      userVisibleOnly: true,
      applicationServerKey: this.urlBase64ToUint8Array(vapidPublicKey)
    })

    const json = subscription.toJSON()
    const csrfToken = document.querySelector('meta[name="csrf-token"]').content

    await fetch("/push_subscriptions", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": csrfToken
      },
      body: JSON.stringify({
        endpoint: json.endpoint,
        p256dh_key: json.keys.p256dh,
        auth_key: json.keys.auth
      })
    })
  }

  async unsubscribe() {
    const registration = await navigator.serviceWorker.ready
    const subscription = await registration.pushManager.getSubscription()

    if (subscription) {
      const endpoint = subscription.endpoint
      await subscription.unsubscribe()

      const csrfToken = document.querySelector('meta[name="csrf-token"]').content

      await fetch("/push_subscriptions", {
        method: "DELETE",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": csrfToken
        },
        body: JSON.stringify({ endpoint: endpoint })
      })
    }
  }

  urlBase64ToUint8Array(base64String) {
    const padding = "=".repeat((4 - base64String.length % 4) % 4)
    const base64 = (base64String + padding).replace(/-/g, "+").replace(/_/g, "/")
    const rawData = window.atob(base64)
    const outputArray = new Uint8Array(rawData.length)
    for (let i = 0; i < rawData.length; ++i) {
      outputArray[i] = rawData.charCodeAt(i)
    }
    return outputArray
  }
}
