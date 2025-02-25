// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import "chartkick"
import "Chart.bundle"
import "chart.js"

document.addEventListener("turbo:before-stream-render", function(event) {
  console.log("Turbo Stream received:", event.target);
});