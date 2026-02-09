# frozen_string_literal: true

class DiagnosticReminderJob < ApplicationJob
  queue_as :default

  def perform
    # Find diagnostics scheduled for tomorrow
    tomorrow_start = 1.day.from_now.beginning_of_day
    tomorrow_end = 1.day.from_now.end_of_day

    diagnostics = Diagnostic.status_scheduled
                            .where(conducted_at: tomorrow_start..tomorrow_end)
                            .includes(:user, :conducted_by)

    diagnostics.find_each do |diagnostic|
      DiagnosticMailer.reminder(diagnostic).deliver_later
      Rails.logger.info "Sent diagnostic reminder to #{diagnostic.user.email} for diagnostic #{diagnostic.id}"
    end
  end
end
