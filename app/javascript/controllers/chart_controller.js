import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="chart"
export default class extends Controller {
  static values = {
    type: String,      // 'line' or 'bar'
    data: Array,       // Chart data
    label: String      // Y-axis label
  }

  connect() {
    this.renderChart()
  }

  renderChart() {
    const canvas = this.element.querySelector('canvas')
    if (!canvas) return

    const ctx = canvas.getContext('2d')
    const type = this.typeValue

    // Set canvas size
    const rect = canvas.getBoundingClientRect()
    canvas.width = rect.width * window.devicePixelRatio
    canvas.height = rect.height * window.devicePixelRatio
    ctx.scale(window.devicePixelRatio, window.devicePixelRatio)

    if (type === 'line') {
      this.renderLineChart(ctx, rect.width, rect.height)
    } else if (type === 'bar') {
      this.renderBarChart(ctx, rect.width, rect.height)
    }
  }

  renderLineChart(ctx, width, height) {
    const data = this.dataValue
    if (!data || data.length === 0) return

    const padding = 50
    const chartWidth = width - padding * 2
    const chartHeight = height - padding * 2

    // Find max value
    const maxValue = Math.max(...data.map(d => d.revenue))
    const yScale = chartHeight / (maxValue * 1.1) // Add 10% padding

    // Clear canvas
    ctx.clearRect(0, 0, width, height)

    // Draw axes
    ctx.strokeStyle = '#E5E7EB'
    ctx.lineWidth = 1
    ctx.beginPath()
    ctx.moveTo(padding, padding)
    ctx.lineTo(padding, height - padding)
    ctx.lineTo(width - padding, height - padding)
    ctx.stroke()

    // Draw grid lines
    ctx.strokeStyle = '#F3F4F6'
    for (let i = 0; i <= 5; i++) {
      const y = padding + (chartHeight / 5) * i
      ctx.beginPath()
      ctx.moveTo(padding, y)
      ctx.lineTo(width - padding, y)
      ctx.stroke()

      // Y-axis labels
      const value = Math.round((maxValue * (5 - i)) / 5)
      ctx.fillStyle = '#6B7280'
      ctx.font = '11px -apple-system, system-ui'
      ctx.textAlign = 'right'
      ctx.fillText(value.toLocaleString('ru-RU'), padding - 10, y + 4)
    }

    // Draw line
    const xStep = chartWidth / (data.length - 1)
    ctx.strokeStyle = '#3B82F6'
    ctx.lineWidth = 3
    ctx.beginPath()

    data.forEach((point, index) => {
      const x = padding + index * xStep
      const y = height - padding - (point.revenue * yScale)

      if (index === 0) {
        ctx.moveTo(x, y)
      } else {
        ctx.lineTo(x, y)
      }
    })

    ctx.stroke()

    // Draw points
    data.forEach((point, index) => {
      const x = padding + index * xStep
      const y = height - padding - (point.revenue * yScale)

      ctx.fillStyle = '#3B82F6'
      ctx.beginPath()
      ctx.arc(x, y, 4, 0, Math.PI * 2)
      ctx.fill()

      // Point outline
      ctx.strokeStyle = '#FFFFFF'
      ctx.lineWidth = 2
      ctx.stroke()
    })

    // Draw X-axis labels (show every 5th day)
    ctx.fillStyle = '#6B7280'
    ctx.font = '11px -apple-system, system-ui'
    ctx.textAlign = 'center'

    data.forEach((point, index) => {
      if (index % 5 === 0 || index === data.length - 1) {
        const x = padding + index * xStep
        ctx.fillText(point.date, x, height - padding + 20)
      }
    })
  }

  renderBarChart(ctx, width, height) {
    const data = this.dataValue
    if (!data || data.length === 0) return

    const padding = 60
    const chartWidth = width - padding * 2
    const chartHeight = height - padding * 2

    // Find max value
    const maxValue = Math.max(...data.map(d => d.revenue))
    const yScale = chartHeight / (maxValue * 1.1)

    // Clear canvas
    ctx.clearRect(0, 0, width, height)

    // Draw axes
    ctx.strokeStyle = '#E5E7EB'
    ctx.lineWidth = 1
    ctx.beginPath()
    ctx.moveTo(padding, padding)
    ctx.lineTo(padding, height - padding)
    ctx.lineTo(width - padding, height - padding)
    ctx.stroke()

    // Draw grid lines
    ctx.strokeStyle = '#F3F4F6'
    for (let i = 0; i <= 5; i++) {
      const y = padding + (chartHeight / 5) * i
      ctx.beginPath()
      ctx.moveTo(padding, y)
      ctx.lineTo(width - padding, y)
      ctx.stroke()

      // Y-axis labels
      const value = Math.round((maxValue * (5 - i)) / 5)
      ctx.fillStyle = '#6B7280'
      ctx.font = '11px -apple-system, system-ui'
      ctx.textAlign = 'right'
      ctx.fillText(value.toLocaleString('ru-RU') + ' ₽', padding - 10, y + 4)
    }

    // Draw bars
    const barWidth = chartWidth / data.length * 0.8
    const barGap = chartWidth / data.length * 0.2

    data.forEach((item, index) => {
      const x = padding + (barWidth + barGap) * index + barGap / 2
      const barHeight = item.revenue * yScale
      const y = height - padding - barHeight

      // Bar gradient
      const gradient = ctx.createLinearGradient(0, y, 0, height - padding)
      gradient.addColorStop(0, '#3B82F6')
      gradient.addColorStop(1, '#60A5FA')

      ctx.fillStyle = gradient
      ctx.fillRect(x, y, barWidth, barHeight)

      // Bar value on top
      ctx.fillStyle = '#1F2937'
      ctx.font = 'bold 11px -apple-system, system-ui'
      ctx.textAlign = 'center'
      ctx.fillText(
        Math.round(item.revenue).toLocaleString('ru-RU') + ' ₽',
        x + barWidth / 2,
        y - 5
      )
    })

    // Draw X-axis labels (product names)
    ctx.fillStyle = '#6B7280'
    ctx.font = '11px -apple-system, system-ui'
    ctx.textAlign = 'right'
    ctx.save()

    data.forEach((item, index) => {
      const x = padding + (barWidth + barGap) * index + barGap / 2 + barWidth / 2
      const y = height - padding + 15

      ctx.translate(x, y)
      ctx.rotate(-Math.PI / 4) // 45 degrees

      // Truncate long names
      const maxLength = 25
      const name = item.name.length > maxLength
        ? item.name.substring(0, maxLength) + '...'
        : item.name

      ctx.fillText(name, 0, 0)
      ctx.rotate(Math.PI / 4)
      ctx.translate(-x, -y)
    })

    ctx.restore()
  }
}
