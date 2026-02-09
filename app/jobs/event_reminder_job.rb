# frozen_string_literal: true

class EventReminderJob < ApplicationJob
  queue_as :default

  def perform
    # Find events happening tomorrow
    tomorrow_start = 1.day.from_now.beginning_of_day
    tomorrow_end = 1.day.from_now.end_of_day

    events = Event.status_published
                  .where(starts_at: tomorrow_start..tomorrow_end)

    events.find_each do |event|
      event.event_registrations.active.includes(:user).find_each do |registration|
        EventMailer.reminder(registration).deliver_later
        Rails.logger.info "Sent event reminder to #{registration.user.email} for event #{event.id}"
      end
    end
  end
end
