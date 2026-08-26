import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "installBanner",
    "iosModal",
    "standaloneNotificationCard",
    "installButton",
    "enableNotificationButton",
    "notificationSuccess"
  ]

  connect() {
    this.deferredPrompt = null

    // Capture the beforeinstallprompt event (Android / Chromium)
    window.addEventListener("beforeinstallprompt", (e) => {
      e.preventDefault()
      this.deferredPrompt = e
      this.evaluateDisplay()
    })

    // Listen for app installed event
    window.addEventListener("appinstalled", () => {
      this.deferredPrompt = null
      if (this.hasInstallBannerTarget) {
        this.installBannerTarget.classList.add("hidden")
      }
      this.evaluateDisplay()
    })

    this.evaluateDisplay()
  }

  evaluateDisplay() {
    const isStandalone = this.checkIsStandalone()
    const isIOS = this.checkIsIOS()
    const isMobile = this.checkIsMobile()

    if (isStandalone) {
      // Running inside installed PWA / standalone mode
      if (this.hasInstallBannerTarget) {
        this.installBannerTarget.classList.add("hidden")
      }

      // Check if notifications need to be enabled
      this.checkStandaloneNotificationStatus()
    } else if (isMobile) {
      // Mobile browser (not yet installed)
      const isDismissed = this.isInstallDismissed()
      if (!isDismissed && this.hasInstallBannerTarget) {
        this.installBannerTarget.classList.remove("hidden")
      }
    }
  }

  checkIsStandalone() {
    return (
      window.matchMedia("(display-mode: standalone)").matches ||
      window.navigator.standalone === true ||
      document.referrer.includes("android-app://")
    )
  }

  checkIsIOS() {
    return /iPad|iPhone|iPod/.test(navigator.userAgent) && !window.MSStream
  }

  checkIsMobile() {
    return this.checkIsIOS() || /Android|webOS|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent)
  }

  isInstallDismissed() {
    const dismissedAt = localStorage.getItem("pwa_install_dismissed_at")
    if (!dismissedAt) return false
    const sevenDaysInMs = 7 * 24 * 60 * 60 * 1000
    return Date.now() - parseInt(dismissedAt, 10) < sevenDaysInMs
  }

  dismissInstall() {
    localStorage.setItem("pwa_install_dismissed_at", Date.now().toString())
    if (this.hasInstallBannerTarget) {
      this.installBannerTarget.classList.add("hidden")
    }
  }

  promptInstall() {
    if (this.deferredPrompt) {
      // Android / Chrome native prompt
      this.deferredPrompt.prompt()
      this.deferredPrompt.userChoice.then((choiceResult) => {
        if (choiceResult.outcome === "accepted") {
          if (this.hasInstallBannerTarget) {
            this.installBannerTarget.classList.add("hidden")
          }
        }
        this.deferredPrompt = null
      })
    } else if (this.checkIsIOS()) {
      // Show iOS step-by-step modal guide
      this.showIosModal()
    } else {
      // Fallback for browsers without direct prompt
      this.showIosModal()
    }
  }

  showIosModal() {
    if (this.hasIosModalTarget) {
      this.iosModalTarget.showModal()
    }
  }

  closeIosModal() {
    if (this.hasIosModalTarget) {
      this.iosModalTarget.close()
    }
  }

  async checkStandaloneNotificationStatus() {
    if (!("Notification" in window) || !("serviceWorker" in navigator) || !("PushManager" in window)) {
      return
    }

    if (Notification.permission === "default") {
      // User has not yet granted or denied notifications in standalone mode
      if (this.hasStandaloneNotificationCardTarget) {
        this.standaloneNotificationCardTarget.classList.remove("hidden")
      }
    } else if (Notification.permission === "granted") {
      // Ensure subscription is synchronized
      if (this.hasStandaloneNotificationCardTarget) {
        this.standaloneNotificationCardTarget.classList.add("hidden")
      }
    }
  }

  async enablePushNotifications() {
    if (!("Notification" in window) || !("serviceWorker" in navigator) || !("PushManager" in window)) {
      alert("Push notifications are not supported on this browser.")
      return
    }

    try {
      const permission = await Notification.requestPermission()
      if (permission !== "granted") {
        alert("Notification permission was not granted. You can enable them in your device settings.")
        return
      }

      const registration = await navigator.serviceWorker.ready
      const vapidMeta = document.querySelector('meta[name="vapid-public-key"]')
      const vapidPublicKey = vapidMeta ? vapidMeta.content : ""

      if (!vapidPublicKey) {
        console.warn("VAPID public key not found")
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
        if (this.hasEnableNotificationButtonTarget) {
          this.enableNotificationButtonTarget.classList.add("hidden")
        }
        if (this.hasNotificationSuccessTarget) {
          this.notificationSuccessTarget.classList.remove("hidden")
        }

        // Hide the card after 3 seconds of success feedback
        setTimeout(() => {
          if (this.hasStandaloneNotificationCardTarget) {
            this.standaloneNotificationCardTarget.classList.add("hidden")
          }
        }, 3000)
      }
    } catch (error) {
      console.error("Error enabling push notifications:", error)
      alert("Could not enable notifications: " + error.message)
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
