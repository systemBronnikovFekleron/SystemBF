# frozen_string_literal: true

class EventRegistrationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_event, only: [:create]

  def create
    # Check if user already registered
    if current_user.event_registrations.exists?(event: @event)
      redirect_to @event, alert: 'Вы уже зарегистрированы на это событие'
      return
    end

    # Check if event is full
    if @event.full?
      redirect_to @event, alert: 'Все места заняты'
      return
    end

    # Create registration
    @registration = @event.event_registrations.build(
      user: current_user,
      registered_at: Time.current,
      status: :pending
    )

    if @event.paid?
      # Create order for paid event
      order = create_event_order(@event, @registration)
      if @registration.save
        redirect_to new_order_payment_path(order), notice: 'Регистрация создана. Завершите оплату.'
      else
        redirect_to @event, alert: @registration.errors.full_messages.join(', ')
      end
    else
      # Free event - confirm immediately
      @registration.status = :confirmed
      if @registration.save
        redirect_to @event, notice: 'Вы успешно зарегистрированы на событие!'
      else
        redirect_to @event, alert: @registration.errors.full_messages.join(', ')
      end
    end
  end

  def destroy
    @registration = current_user.event_registrations.find(params[:id])
    @registration.update(status: :cancelled)
    redirect_to dashboard_events_path, notice: 'Регистрация отменена'
  end

  private

  def set_event
    @event = Event.find(params[:event_id])
  end

  def create_event_order(event, registration)
    order = Order.create!(
      user: current_user,
      total_kopecks: event.price_kopecks,
      status: :pending,
      order_number: generate_order_number
    )

    # Link registration with order
    registration.order = order
    order
  end

  def generate_order_number
    year = Date.today.year
    last_order = Order.where("order_number LIKE ?", "BR-#{year}-%").order(:created_at).last
    sequence = last_order ? last_order.order_number.split('-').last.to_i + 1 : 1
    "BR-#{year}-#{sequence.to_s.rjust(4, '0')}"
  end
end
