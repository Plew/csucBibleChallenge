import { Controller } from "@hotwired/stimulus"

// Client-side row filtering by a text query against each row's data-search-text attribute.
export default class extends Controller {
  static targets = ["input", "row"]

  filter() {
    const query = this.inputTarget.value.toLowerCase().trim()
    this.rowTargets.forEach(row => {
      const searchText = (row.dataset.searchText || "").toLowerCase()
      row.classList.toggle("hidden", query.length > 0 && !searchText.includes(query))
    })
  }
}
