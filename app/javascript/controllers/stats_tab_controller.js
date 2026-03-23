import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "myStatsPanel", "communityPanel", "myStatsTab", "communityTab" ]

  connect() {
    const saved = localStorage.getItem("statsActiveTab")
    if (saved === "my") {
      this.showMyStats()
    } else {
      this.showCommunity()
    }
  }

  showMyStats() {
    this.myStatsPanelTarget.classList.remove("hidden")
    this.communityPanelTarget.classList.add("hidden")
    this.myStatsTabTarget.classList.add("tab-active")
    this.communityTabTarget.classList.remove("tab-active")
    localStorage.setItem("statsActiveTab", "my")
  }

  showCommunity() {
    this.communityPanelTarget.classList.remove("hidden")
    this.myStatsPanelTarget.classList.add("hidden")
    this.communityTabTarget.classList.add("tab-active")
    this.myStatsTabTarget.classList.remove("tab-active")
    localStorage.setItem("statsActiveTab", "community")
  }
}
