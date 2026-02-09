import { Controller } from "@hotwired/stimulus"

// Calendar controller for interactive monthly event calendar
// Connects to data-controller="calendar"
export default class extends Controller {
  static targets = ["month", "year", "grid", "selectedDay", "eventList"]
  static values = {
    events: Array,
    currentDate: String
  }

  connect() {
    this.date = this.currentDateValue ? new Date(this.currentDateValue) : new Date()
    this.selectedDate = null
    this.render()
  }

  // Navigation
  previousMonth() {
    this.date.setMonth(this.date.getMonth() - 1)
    this.render()
  }

  nextMonth() {
    this.date.setMonth(this.date.getMonth() + 1)
    this.render()
  }

  today() {
    this.date = new Date()
    this.render()
  }

  // Main render function
  render() {
    this.renderHeader()
    this.renderGrid()
    this.renderSelectedDayEvents()
  }

  renderHeader() {
    const months = [
      'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
      'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'
    ]
    this.monthTarget.textContent = months[this.date.getMonth()]
    this.yearTarget.textContent = this.date.getFullYear()
  }

  renderGrid() {
    const year = this.date.getFullYear()
    const month = this.date.getMonth()

    // First day of month and total days
    const firstDay = new Date(year, month, 1)
    const lastDay = new Date(year, month + 1, 0)
    const totalDays = lastDay.getDate()

    // Start from Monday (adjust for week starting on Monday)
    let startingDay = firstDay.getDay()
    startingDay = startingDay === 0 ? 6 : startingDay - 1

    // Build grid HTML
    let html = ''
    let dayCount = 1

    // 6 weeks max
    for (let week = 0; week < 6; week++) {
      html += '<div class="calendar-week">'

      for (let day = 0; day < 7; day++) {
        const cellIndex = week * 7 + day

        if (cellIndex < startingDay || dayCount > totalDays) {
          // Empty cell
          html += '<div class="calendar-cell calendar-cell--empty"></div>'
        } else {
          const cellDate = new Date(year, month, dayCount)
          const dateStr = this.formatDate(cellDate)
          const isToday = this.isToday(cellDate)
          const isSelected = this.selectedDate && dateStr === this.formatDate(this.selectedDate)
          const dayEvents = this.getEventsForDate(dateStr)
          const hasEvents = dayEvents.length > 0

          let classes = 'calendar-cell'
          if (isToday) classes += ' calendar-cell--today'
          if (isSelected) classes += ' calendar-cell--selected'
          if (hasEvents) classes += ' calendar-cell--has-events'

          html += `<div class="${classes}" data-action="click->calendar#selectDay" data-date="${dateStr}">`
          html += `<span class="calendar-day-number">${dayCount}</span>`

          // Event indicators (dots)
          if (hasEvents) {
            html += '<div class="calendar-event-dots">'
            dayEvents.slice(0, 3).forEach(event => {
              const dotClass = event.is_online ? 'dot--online' : 'dot--offline'
              html += `<span class="calendar-dot ${dotClass}"></span>`
            })
            if (dayEvents.length > 3) {
              html += `<span class="calendar-dot-more">+${dayEvents.length - 3}</span>`
            }
            html += '</div>'
          }

          html += '</div>'
          dayCount++
        }
      }

      html += '</div>'

      // Stop if we've rendered all days
      if (dayCount > totalDays) break
    }

    this.gridTarget.innerHTML = html
  }

  renderSelectedDayEvents() {
    if (!this.selectedDate) {
      this.selectedDayTarget.textContent = 'Выберите день'
      this.eventListTarget.innerHTML = '<div class="calendar-no-events">Выберите день на календаре</div>'
      return
    }

    const dateStr = this.formatDate(this.selectedDate)
    const dayEvents = this.getEventsForDate(dateStr)

    // Format selected day display
    const options = { weekday: 'long', day: 'numeric', month: 'long' }
    this.selectedDayTarget.textContent = this.selectedDate.toLocaleDateString('ru-RU', options)

    if (dayEvents.length === 0) {
      this.eventListTarget.innerHTML = '<div class="calendar-no-events">Нет событий в этот день</div>'
      return
    }

    let html = ''
    dayEvents.forEach(event => {
      const time = event.starts_at.substring(11, 16)
      const typeClass = event.is_online ? 'event-card--online' : 'event-card--offline'
      const badge = event.is_online ? '<span class="event-badge event-badge--online">Онлайн</span>' : '<span class="event-badge event-badge--offline">Офлайн</span>'

      html += `
        <a href="${event.url}" class="calendar-event-card ${typeClass}">
          <div class="event-card-time">${time}</div>
          <div class="event-card-content">
            <h4 class="event-card-title">${this.escapeHtml(event.title)}</h4>
            <div class="event-card-meta">
              ${badge}
              ${event.location ? `<span class="event-location">${this.escapeHtml(event.location)}</span>` : ''}
              ${event.price ? `<span class="event-price">${event.price}</span>` : '<span class="event-free">Бесплатно</span>'}
            </div>
          </div>
        </a>
      `
    })

    this.eventListTarget.innerHTML = html
  }

  selectDay(e) {
    const dateStr = e.currentTarget.dataset.date
    if (dateStr) {
      this.selectedDate = new Date(dateStr)
      this.render()
    }
  }

  // Helper functions
  formatDate(date) {
    return date.toISOString().split('T')[0]
  }

  isToday(date) {
    const today = new Date()
    return date.getDate() === today.getDate() &&
           date.getMonth() === today.getMonth() &&
           date.getFullYear() === today.getFullYear()
  }

  getEventsForDate(dateStr) {
    return this.eventsValue.filter(event => {
      const eventDate = event.starts_at.substring(0, 10)
      return eventDate === dateStr
    })
  }

  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }
}
