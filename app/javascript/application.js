// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import "chartkick"
import "Chart.bundle"

function setDateCookie() {
    const today = new Date();
    const formattedDate = today.toISOString().split('T')[0]; // Format: YYYY-MM-DD
    document.cookie = `browser_date=${formattedDate}; path=/; max-age=86400`; // Expires in 24 hours
  }
  
  // Call this function when the page loads
  document.addEventListener('turbo:load', setDateCookie);
  document.addEventListener('turbo:load', () => {
  });


  document.addEventListener("turbo:before-stream-render", function(event) {
    console.log("Turbo Stream received:", event.target);
  });