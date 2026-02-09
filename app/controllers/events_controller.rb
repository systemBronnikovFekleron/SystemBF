# frozen_string_literal: true

class EventsController < ApplicationController
  before_action :set_event, only: [:show, :ics]

  def index
    @events = Event.status_published.accessible_by(current_user).upcoming

    # Filters
    @events = @events.where(category_id: params[:category_id]) if params[:category_id].present?
    @events = @events.where(is_online: params[:online] == 'true') if params[:online].present?

    # Pagination
    @events = @events.ordered.page(params[:page]).per(12)
  end

  def show
    unless @event.accessible_by?(current_user)
      redirect_to events_path, alert: 'У вас нет доступа к этому событию'
      return
    end
    @registration = current_user&.event_registrations&.find_by(event: @event)
  end

  def calendar
    @events = Event.status_published.accessible_by(current_user).includes(:category).ordered
    @events_by_date = @events.group_by { |e| e.starts_at.to_date }

    # Prepare events data for JavaScript calendar
    @events_json = @events.map do |event|
      {
        id: event.id,
        title: event.title,
        starts_at: event.starts_at.iso8601,
        ends_at: event.ends_at&.iso8601,
        is_online: event.is_online?,
        location: event.location,
        price: event.free? ? nil : helpers.humanized_money_with_symbol(event.price),
        url: event_path(event),
        category: event.category&.name
      }
    end
  end

  def ics
    ics_content = IcsGeneratorService.generate_event(@event)

    send_data ics_content,
              type: 'text/calendar; charset=utf-8',
              disposition: 'attachment',
              filename: "#{@event.slug}.ics"
  end

  private

  def set_event
    @event = Event.friendly.find(params[:id])
  end
end
