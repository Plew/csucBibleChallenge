// Minimal service worker for PWA installability and Web Push notifications.
// Uses network-first strategy — Turbo handles navigation caching.

self.addEventListener("install", (event) => {
  self.skipWaiting()
})

self.addEventListener("activate", (event) => {
  event.waitUntil(clients.claim())
})

// Listen for incoming Web Push notifications from Rails (WebPush gem)
self.addEventListener("push", (event) => {
  if (!event.data) return

  let title = "And God Said"
  let options = {
    icon: "/icons/icon-192x192.png",
    badge: "/icons/icon-48x48.png",
    vibrate: [100, 50, 100],
    data: { path: "/reading" }
  }

  try {
    const payload = event.data.json()
    if (payload.title) title = payload.title
    if (payload.options) {
      options = {
        ...options,
        ...payload.options,
        icon: payload.options.icon || "/icons/icon-192x192.png",
        badge: payload.options.badge || "/icons/icon-48x48.png",
        data: {
          path: payload.options.data?.path || "/reading"
        }
      }
    }
  } catch (e) {
    options.body = event.data.text()
  }

  event.waitUntil(self.registration.showNotification(title, options))
})

// Deep link to reading/target page when tapping notification
self.addEventListener("notificationclick", (event) => {
  event.notification.close()

  const targetPath = event.notification.data?.path || "/reading"

  event.waitUntil(
    clients.matchAll({ type: "window", includeUncontrolled: true }).then((clientList) => {
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
      if (clients.openWindow) {
        return clients.openWindow(targetPath)
      }
    })
  )
})
