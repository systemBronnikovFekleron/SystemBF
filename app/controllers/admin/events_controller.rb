# frozen_string_literal: true

module Admin
  class EventsController < Admin::BaseController
    before_action :set_event, only: [:show, :edit, :update, :destroy, :registrations]

    def index
      @events = Event.includes(:category, :organizer).ordered

      # Filters
      @events = @events.where(status: params[:status]) if params[:status].present?
      @events = @events.where(category_id: params[:category_id]) if params[:category_id].present?
      @events = @events.upcoming if params[:time] == 'upcoming'
      @events = @events.past if params[:time] == 'past'

      @events = @events.page(params[:page]).per(20)

      # Stats
      @total_count = Event.count
      @upcoming_count = Event.upcoming.count
      @past_count = Event.past.count
    end

    def show
      @registrations = @event.event_registrations.includes(:user).order(created_at: :desc).limit(10)
    end

    def new
      @event = Event.new
      @categories = Category.ordered
    end

    def create
      @event = Event.new(event_params)
      @event.organizer = current_user

      if @event.save
        redirect_to admin_event_path(@event), notice: 'Событие успешно создано'
      else
        @categories = Category.ordered
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @categories = Category.ordered
    end

    def update
      if @event.update(event_params)
        redirect_to admin_event_path(@event), notice: 'Событие успешно обновлено'
      else
        @categories = Category.ordered
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @event.destroy
      redirect_to admin_events_path, notice: 'Событие удалено'
    end

    def registrations
      @registrations = @event.event_registrations
                            .includes(:user, :order)
                            .order(created_at: :desc)
                            .page(params[:page]).per(20)

      @confirmed_count = @event.event_registrations.where(status: :confirmed).count
      @pending_count = @event.event_registrations.where(status: :pending).count
      @cancelled_count = @event.event_registrations.where(status: :cancelled).count
    end

    def bulk_action
      action = params[:bulk_action]
      event_ids = params[:event_ids] || []

      case action
      when 'publish'
        Event.where(id: event_ids).update_all(status: :published)
        message = "#{event_ids.count} событий опубликовано"
      when 'cancel'
        Event.where(id: event_ids).update_all(status: :cancelled)
        message = "#{event_ids.count} событий отменено"
      when 'complete'
        Event.where(id: event_ids).update_all(status: :completed)
        message = "#{event_ids.count} событий завершено"
      when 'delete'
        Event.where(id: event_ids).destroy_all
        message = "#{event_ids.count} событий удалено"
      else
        message = 'Неизвестное действие'
      end

      redirect_to admin_events_path, notice: message
    end

    private

    def set_event
      @event = Event.friendly.find(params[:id])
    end

    def event_params
      params.require(:event).permit(
        :title, :slug, :description, :starts_at, :ends_at,
        :location, :is_online, :max_participants, :price_kopecks,
        :category_id, :status
      )
    end
  end
end
