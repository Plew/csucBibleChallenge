import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  change(event) {
    const selectedValue = event.target.value
    const currentUrl = new URL(window.location)

    // Update URL with sprint_id parameter
    if (selectedValue === "full") {
      currentUrl.searchParams.delete("sprint_id")
    } else {
      currentUrl.searchParams.set("sprint_id", selectedValue)
    }

    // Reload the page with the new parameter
    window.location.href = currentUrl.toString()
  }
}
