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
      localStorage.setItem("pwa_install_dismissed", "true")
      localStorage.setItem("pwa_installed", "true")
      if (this.hasInstallBannerTarget) {
        this.installBannerTarget.classList.add("hidden")
      }
    })

    this.evaluateDisplay()
  }

  evaluateDisplay() {
    const isStandalone = this.checkIsStandalone()
    const isIOS = this.checkIsIOS()
    const isMobile = this.checkIsMobile()
    const isDismissed = localStorage.getItem("pwa_install_dismissed") === "true" || localStorage.getItem("pwa_installed") === "true"

    if (isStandalone) {
      // In standalone mode, hide install banner
      if (this.hasInstallBannerTarget) {
        this.installBannerTarget.classList.add("hidden")
      }

      // Check if standalone notification prompt should show (only once, if not dismissed)
      this.checkStandaloneNotificationStatus()
    } else if (isMobile && !isDismissed) {
      // Show install banner only if never dismissed/installed
      if (this.hasInstallBannerTarget) {
        this.installBannerTarget.classList.remove("hidden")
      }
    } else {
      if (this.hasInstallBannerTarget) {
        this.installBannerTarget.classList.add("hidden")
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

  dismissInstall() {
    localStorage.setItem("pwa_install_dismissed", "true")
    if (this.hasInstallBannerTarget) {
      this.installBannerTarget.classList.add("hidden")
    }
  }

  promptInstall() {
    // Hide and permanently dismiss banner so it never reappears in browser
    this.dismissInstall()

    if (this.deferredPrompt) {
      // Android native prompt
      this.deferredPrompt.prompt()
      this.deferredPrompt.userChoice.then((choiceResult) => {
        if (choiceResult.outcome === "accepted") {
          localStorage.setItem("pwa_installed", "true")
        }
        this.deferredPrompt = null
      })
    } else {
      // iOS or browsers without direct prompt
      this.showIosModal()
    }
  }

  showIosModal() {
    this.dismissInstall()
    if (this.hasIosModalTarget) {
      this.iosModalTarget.showModal()
    }
  }

  closeIosModal() {
    this.dismissInstall()
    if (this.hasIosModalTarget) {
      this.iosModalTarget.close()
    }
  }

  dismissStandaloneNotification() {
    localStorage.setItem("pwa_standalone_notification_dismissed", "true")
    if (this.hasStandaloneNotificationCardTarget) {
      this.standaloneNotificationCardTarget.classList.add("hidden")
    }
  }

  async checkStandaloneNotificationStatus() {
    if (!("Notification" in window) || !("serviceWorker" in navigator) || !("PushManager" in window)) {
      return
    }

    const isNotificationDismissed = localStorage.getItem("pwa_standalone_notification_dismissed") === "true"

    // Only show if user has never dismissed it AND permission is still default
    if (!isNotificationDismissed && Notification.permission === "default") {
      if (this.hasStandaloneNotificationCardTarget) {
        this.standaloneNotificationCardTarget.classList.remove("hidden")
      }
    } else {
      if (this.hasStandaloneNotificationCardTarget) {
        this.standaloneNotificationCardTarget.classList.add("hidden")
      }
    }
  }

  async enablePushNotifications() {
    // Mark as dismissed so prompt never appears again
    localStorage.setItem("pwa_standalone_notification_dismissed", "true")

    if (!("Notification" in window) || !("serviceWorker" in navigator) || !("PushManager" in window)) {
      alert("Push notifications are not supported on this browser.")
      return
    }

    try {
      const permission = await Notification.requestPermission()
      if (permission !== "granted") {
        if (this.hasStandaloneNotificationCardTarget) {
          this.standaloneNotificationCardTarget.classList.add("hidden")
        }
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

        setTimeout(() => {
          if (this.hasStandaloneNotificationCardTarget) {
            this.standaloneNotificationCardTarget.classList.add("hidden")
          }
        }, 2500)
      }
    } catch (error) {
      console.error("Error enabling push notifications:", error)
      if (this.hasStandaloneNotificationCardTarget) {
        this.standaloneNotificationCardTarget.classList.add("hidden")
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
