// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails

// Shim for process.env.NODE_ENV for libraries expecting a Node-like environment
if (typeof window.process === 'undefined') {
  const railsEnvMeta = document.querySelector('meta[name="rails-env"]');
  const railsEnv = railsEnvMeta ? railsEnvMeta.content : 'production'; // Default to production if meta tag not found
  window.process = {
    env: {
      NODE_ENV: railsEnv
    }
  };
}

import "@hotwired/turbo-rails"
import "controllers"

window.Turbo.setProgressBarDelay(100)
import "chartkick"
import "Chart.bundle"
import "chart.js"

if ("serviceWorker" in navigator) {
  navigator.serviceWorker.register("/service-worker", { scope: "/" }).then((registration) => {
    registration.update()
  }).catch((err) => {
    console.warn("ServiceWorker registration error:", err)
  })
}

document.addEventListener("turbo:before-stream-render", function(event) {
  console.log("Turbo Stream received:", event.target);
});
