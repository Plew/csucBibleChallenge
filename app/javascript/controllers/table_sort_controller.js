import { Controller } from "@hotwired/stimulus"

// Client-side table sorting. Attach to a <table>.
// Sortable headers: data-action="click->table-sort#sort" data-table-sort-target="header"
//   data-sort-key="completion" data-sort-type="number"
// Each body <tr> carries the values: data-completion="85" data-ontime="40" data-name="alice"
export default class extends Controller {
  static targets = ["body", "header"]

  sort(event) {
    const header = event.currentTarget
    const key = header.dataset.sortKey
    const type = header.dataset.sortType || "string"

    let direction
    if (this.currentKey === key) {
      direction = this.currentDirection === "asc" ? "desc" : "asc"
    } else {
      // First click: numbers high-to-low, names A-to-Z
      direction = type === "number" ? "desc" : "asc"
    }
    this.currentKey = key
    this.currentDirection = direction

    const rows = Array.from(this.bodyTarget.querySelectorAll("tr"))
    rows.sort((a, b) => {
      const av = a.dataset[key]
      const bv = b.dataset[key]
      let cmp
      if (type === "number") {
        cmp = Number(av) - Number(bv)
      } else {
        cmp = (av || "").localeCompare(bv || "")
      }
      return direction === "asc" ? cmp : -cmp
    })
    rows.forEach((row) => this.bodyTarget.appendChild(row))

    this.updateIndicators(key, direction)
  }

  updateIndicators(activeKey, direction) {
    this.headerTargets.forEach((header) => {
      const arrow = header.querySelector("[data-arrow]")
      if (!arrow) return
      arrow.textContent = header.dataset.sortKey === activeKey ? (direction === "asc" ? "▲" : "▼") : ""
    })
  }
}
