import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    url: String,
    groupId: String
  }

  connect() {
    this.loadChartData()
  }

  async loadChartData() {
    try {
      const response = await fetch(this.urlValue)
      if (!response.ok) throw new Error('Network response was not ok')
      const { data } = await response.json()
      
      this.initializeChart(this.transformData(data))
    } catch (error) {
      console.error('Error loading chart data:', error)
    }
  }

  transformData(data) {
    const checkedIn = data.filter(item => item.checked_in_value === 1).length
    const notCheckedIn = data.filter(item => item.checked_in_value === 0).length

    return {
      labels: ['Checked In', 'Not Checked In'],
      datasets: [{
        data: [checkedIn, notCheckedIn],
        backgroundColor: ['#4CAF50', '#f44336'],
        borderWidth: 0,
        cutout: '70%'
      }]
    }
  }

  initializeChart(chartData) {
    const ctx = this.element
    
    new window.Chart(ctx, {
      type: 'doughnut',
      data: chartData,
      options: {
        responsive: true,
        maintainAspectRatio: true,
        plugins: {
          legend: {
            display: false
          },
          tooltip: {
            callbacks: {
              label: () => ''
            }
          }
        }
      }
    })
  }
} 