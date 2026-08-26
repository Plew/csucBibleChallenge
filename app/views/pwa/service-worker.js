// Minimal service worker for PWA installability and Web Push notifications.
// Version: 2.1.0
// Uses network-first strategy — Turbo handles navigation caching.

self.addEventListener("install", (event) => {
  self.skipWaiting()
})

self.addEventListener("activate", (event) => {
  event.waitUntil(self.clients.claim())
})

// Listen for incoming Web Push notifications from Rails (WebPush gem)
self.addEventListener("push", (event) => {
  let title = "And God Said"
  let options = {
    body: "You have a new update.",
    icon: "/icons/icon-192x192.png?v=3",
    badge: "/icons/icon-48x48.png?v=3",
    vibrate: [100, 50, 100],
    data: { path: "/reading" }
  }

  if (event.data) {
    try {
      const payload = event.data.json()
      if (payload && typeof payload === "object") {
        if (payload.title) title = payload.title
        if (payload.options) {
          options = Object.assign({}, options, payload.options)
        } else if (payload.body) {
          options.body = payload.body
        }
      }
    } catch (e) {
      try {
        options.body = event.data.text()
      } catch (textErr) {}
    }
  }

  event.waitUntil(self.registration.showNotification(title, options))
})

// Deep link to reading/target page when tapping notification
self.addEventListener("notificationclick", (event) => {
  event.notification.close()

  const targetPath = event.notification.data?.path || "/reading"

  event.waitUntil(
    self.clients.matchAll({ type: "window", includeUncontrolled: true }).then((clientList) => {
      // If a window is already open, focus it and navigate to target
      for (let i = 0; i < clientList.length; i++) {
        let client = clientList[i]
        let clientUrl = new URL(client.url)

        if (clientUrl.origin === self.location.origin && "focus" in client) {
          if (clientUrl.pathname !== targetPath && "navigate" in client) {
            client.navigate(targetPath)
          }
          return client.focus()
        }
      }

      // Otherwise open a new standalone window/tab
      if (self.clients.openWindow) {
        return self.clients.openWindow(targetPath)
      }
    })
  )
})
