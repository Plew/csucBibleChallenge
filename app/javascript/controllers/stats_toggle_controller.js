import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Initialize: show sprint by default
    this.showingSprint = true
  }

  toggle(event) {
    event.preventDefault()

    // Toggle the state
    this.showingSprint = !this.showingSprint

    // Toggle label visibility
    const sprintModeLabel = document.getElementById('sprint-mode-label')
    const challengeModeLabel = document.getElementById('challenge-mode-label')

    if (this.showingSprint) {
      sprintModeLabel.classList.remove('hidden')
      challengeModeLabel.classList.add('hidden')
    } else {
      sprintModeLabel.classList.add('hidden')
      challengeModeLabel.classList.remove('hidden')
    }

    // Toggle stats sections
    const sprintStats = document.getElementById('sprint-stats')
    const challengeStats = document.getElementById('challenge-stats')

    if (this.showingSprint) {
      // Show sprint stats, hide challenge stats
      sprintStats.classList.remove('hidden')
      challengeStats.classList.add('hidden')
    } else {
      // Show challenge stats, hide sprint stats
      sprintStats.classList.add('hidden')
      challengeStats.classList.remove('hidden')
    }

    // Toggle reading history graphs for all users
    const sprintGraphs = document.querySelectorAll('.sprint-graph')
    const challengeGraphs = document.querySelectorAll('.challenge-graph')

    if (this.showingSprint) {
      // Show sprint graphs, hide challenge graphs
      sprintGraphs.forEach(graph => graph.classList.remove('hidden'))
      challengeGraphs.forEach(graph => graph.classList.add('hidden'))
    } else {
      // Show challenge graphs, hide sprint graphs
      sprintGraphs.forEach(graph => graph.classList.add('hidden'))
      challengeGraphs.forEach(graph => graph.classList.remove('hidden'))
    }
  }
}
