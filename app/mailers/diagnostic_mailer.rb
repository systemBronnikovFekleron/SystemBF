# frozen_string_literal: true

class DiagnosticMailer < ApplicationMailer
  default from: 'noreply@bronnikov.com'

  def reminder(diagnostic)
    @diagnostic = diagnostic
    @user = diagnostic.user
    @conducted_by = diagnostic.conducted_by

    mail(
      to: @user.email,
      subject: "Напоминание: диагностика #{@diagnostic.display_name} — завтра!"
    )
  end

  def scheduled(diagnostic)
    @diagnostic = diagnostic
    @user = diagnostic.user
    @conducted_by = diagnostic.conducted_by

    mail(
      to: @user.email,
      subject: "Диагностика #{@diagnostic.display_name} назначена"
    )
  end

  def completed(diagnostic)
    @diagnostic = diagnostic
    @user = diagnostic.user
    @conducted_by = diagnostic.conducted_by

    mail(
      to: @user.email,
      subject: "Диагностика #{@diagnostic.display_name} завершена"
    )
  end
end
