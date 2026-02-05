# frozen_string_literal: true

class EventsController < ApplicationController
  before_action :set_event, only: [:show]

  def index
    @events = Event.status_published.upcoming.includes(:category, :organizer)

    # Filters
    @events = @events.where(category_id: params[:category_id]) if params[:category_id].present?
    @events = @events.where(is_online: params[:online] == 'true') if params[:online].present?

    # Pagination
    @events = @events.ordered.page(params[:page]).per(12)
  end

  def show
    @registration = current_user&.event_registrations&.find_by(event: @event)
  end

  def calendar
    @events = Event.status_published.includes(:category).ordered
    @events_by_date = @events.group_by { |e| e.starts_at.to_date }
  end

  private

  def set_event
    @event = Event.friendly.find(params[:id])
  end
end
