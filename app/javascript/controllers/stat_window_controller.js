import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  change(event) {
    const selectedValue = event.target.value
    const currentUrl = new URL(window.location)

    // Update URL with stat_window_id parameter
    if (selectedValue === "full") {
      currentUrl.searchParams.delete("stat_window_id")
    } else {
      currentUrl.searchParams.set("stat_window_id", selectedValue)
    }

    // Reload the page with the new parameter
    window.location.href = currentUrl.toString()
  }
}
