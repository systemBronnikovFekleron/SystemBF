# frozen_string_literal: true

require 'icalendar'

class IcsGeneratorService
  class << self
    # Generate ICS for a single event
    def generate_event(event)
      calendar = Icalendar::Calendar.new

      calendar.event do |e|
        e.dtstart = Icalendar::Values::DateTime.new(event.starts_at)
        e.dtend = Icalendar::Values::DateTime.new(event.ends_at || event.starts_at + 2.hours)
        e.summary = event.title
        e.description = event.description
        e.location = event.is_online? ? 'Онлайн' : event.location
        e.url = Rails.application.routes.url_helpers.event_url(event, host: default_host)
        e.uid = "event-#{event.id}@#{default_host}"
        e.created = Icalendar::Values::DateTime.new(event.created_at)
        e.last_modified = Icalendar::Values::DateTime.new(event.updated_at)

        # Add alarm 1 day before
        e.alarm do |a|
          a.action = 'DISPLAY'
          a.trigger = '-P1D'
          a.description = "Напоминание: #{event.title}"
        end
      end

      calendar.publish
      calendar.to_ical
    end

    # Generate ICS for user's registered events
    def generate_user_events(user)
      calendar = Icalendar::Calendar.new
      calendar.x_wr_calname = "Мои события - Система Бронникова"

      user.registered_events.status_published.upcoming.find_each do |event|
        calendar.event do |e|
          e.dtstart = Icalendar::Values::DateTime.new(event.starts_at)
          e.dtend = Icalendar::Values::DateTime.new(event.ends_at || event.starts_at + 2.hours)
          e.summary = event.title
          e.description = event.description
          e.location = event.is_online? ? 'Онлайн' : event.location
          e.url = Rails.application.routes.url_helpers.event_url(event, host: default_host)
          e.uid = "event-#{event.id}@#{default_host}"

          e.alarm do |a|
            a.action = 'DISPLAY'
            a.trigger = '-P1D'
            a.description = "Напоминание: #{event.title}"
          end
        end
      end

      calendar.publish
      calendar.to_ical
    end

    # Generate ICS for user's diagnostics
    def generate_user_diagnostics(user)
      calendar = Icalendar::Calendar.new
      calendar.x_wr_calname = "Мои диагностики - Система Бронникова"

      user.diagnostics.status_scheduled.where.not(conducted_at: nil).find_each do |diagnostic|
        calendar.event do |e|
          e.dtstart = Icalendar::Values::DateTime.new(diagnostic.conducted_at)
          e.dtend = Icalendar::Values::DateTime.new(diagnostic.conducted_at + 1.hour)
          e.summary = diagnostic.display_name
          e.description = "Диагностика #{diagnostic.diagnostic_type}"
          e.location = 'Система Бронникова'
          e.uid = "diagnostic-#{diagnostic.id}@#{default_host}"

          e.alarm do |a|
            a.action = 'DISPLAY'
            a.trigger = '-P1D'
            a.description = "Напоминание: #{diagnostic.display_name}"
          end
        end
      end

      calendar.publish
      calendar.to_ical
    end

    # Generate combined calendar for user
    def generate_user_calendar(user)
      calendar = Icalendar::Calendar.new
      calendar.x_wr_calname = "Мой календарь - Система Бронникова"

      # Add events
      user.registered_events.status_published.upcoming.find_each do |event|
        calendar.event do |e|
          e.dtstart = Icalendar::Values::DateTime.new(event.starts_at)
          e.dtend = Icalendar::Values::DateTime.new(event.ends_at || event.starts_at + 2.hours)
          e.summary = "[Событие] #{event.title}"
          e.description = event.description
          e.location = event.is_online? ? 'Онлайн' : event.location
          e.url = Rails.application.routes.url_helpers.event_url(event, host: default_host)
          e.uid = "event-#{event.id}@#{default_host}"

          e.alarm do |a|
            a.action = 'DISPLAY'
            a.trigger = '-P1D'
            a.description = "Напоминание: #{event.title}"
          end
        end
      end

      # Add diagnostics
      user.diagnostics.status_scheduled.where.not(conducted_at: nil).find_each do |diagnostic|
        calendar.event do |e|
          e.dtstart = Icalendar::Values::DateTime.new(diagnostic.conducted_at)
          e.dtend = Icalendar::Values::DateTime.new(diagnostic.conducted_at + 1.hour)
          e.summary = "[Диагностика] #{diagnostic.display_name}"
          e.description = "Диагностика #{diagnostic.diagnostic_type}"
          e.location = 'Система Бронникова'
          e.uid = "diagnostic-#{diagnostic.id}@#{default_host}"

          e.alarm do |a|
            a.action = 'DISPLAY'
            a.trigger = '-P1D'
            a.description = "Напоминание: #{diagnostic.display_name}"
          end
        end
      end

      calendar.publish
      calendar.to_ical
    end

    private

    def default_host
      Rails.application.config.action_mailer.default_url_options&.dig(:host) || 'bronnikov.com'
    end
  end
end
