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
import "chartkick"
import "Chart.bundle"
import "chart.js"

console.log('fooo');

document.addEventListener("turbo:before-stream-render", function(event) {
  console.log("Turbo Stream received:", event.target);
});

// --- Stagewise Toolbar Initialization (Fallback) ---

// Define basic config
const stagewiseConfig = { plugins: [] }; 

const railsEnv = document.querySelector('meta[name="rails-env"]')?.content;
console.log('railsEnv', railsEnv);
if (railsEnv === 'development') {
  // Place your development-specific JavaScript code here
  // For example, the Stagewise Toolbar initialization
  (async () => {
    try {
      // Check if already initialized
      if (!document.getElementById('stagewise-toolbar-root-vanilla')) {
        const stagewiseCore = await import('@stagewise/toolbar');
        stagewiseCore.initToolbar(stagewiseConfig);
        // Mark that initialization has run
        const marker = document.createElement('div');
        marker.id = 'stagewise-toolbar-root-vanilla';
        marker.style.display = 'none';
        document.body.appendChild(marker);
        console.log('Stagewise Toolbar (Vanilla JS) initialized via automatic setup.');
      }
    } catch (error) {
      console.error('Failed to initialize Stagewise Toolbar (Vanilla JS):', error);
    }
  })();
}
// --- End Stagewise Initialization ---