# frozen_string_literal: true

class EventMailer < ApplicationMailer
  default from: 'noreply@bronnikov.com'

  def reminder(registration)
    @registration = registration
    @event = registration.event
    @user = registration.user

    mail(
      to: @user.email,
      subject: "Напоминание: #{@event.title} — завтра!"
    )
  end

  def registration_confirmation(registration)
    @registration = registration
    @event = registration.event
    @user = registration.user

    mail(
      to: @user.email,
      subject: "Вы зарегистрированы на #{@event.title}"
    )
  end

  def cancellation(registration)
    @registration = registration
    @event = registration.event
    @user = registration.user

    mail(
      to: @user.email,
      subject: "Отмена регистрации: #{@event.title}"
    )
  end
end
