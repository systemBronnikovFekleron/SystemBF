# frozen_string_literal: true

module Admin
  class InteractionHistoriesController < BaseController
    before_action :set_interaction_history, only: [:show, :edit, :update]

    def index
      @interaction_histories = InteractionHistory.includes(:user, :admin_user).recent

      # Поиск
      if params[:search].present?
        @interaction_histories = @interaction_histories.joins(:user).where(
          'users.email ILIKE ? OR users.first_name ILIKE ? OR users.last_name ILIKE ? OR interaction_histories.subject ILIKE ?',
          "%#{params[:search]}%", "%#{params[:search]}%", "%#{params[:search]}%", "%#{params[:search]}%"
        )
      end

      # Фильтр по типу взаимодействия
      if params[:interaction_type].present?
        @interaction_histories = @interaction_histories.where(interaction_type: params[:interaction_type])
      end

      # Фильтр по статусу
      if params[:status].present?
        @interaction_histories = @interaction_histories.where(status: params[:status])
      end

      # Фильтр по клиенту
      if params[:user_id].present?
        @interaction_histories = @interaction_histories.where(user_id: params[:user_id])
      end

      @interaction_histories = @interaction_histories.page(params[:page]).per(20)
    end

    def show
      # show view
    end

    def new
      @interaction_history = InteractionHistory.new
      load_users
    end

    def create
      @interaction_history = InteractionHistory.new(interaction_history_params)
      @interaction_history.admin_user = current_user

      if @interaction_history.save
        redirect_to admin_interaction_history_path(@interaction_history), notice: 'Запись о взаимодействии успешно создана'
      else
        load_users
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      load_users
    end

    def update
      if @interaction_history.update(interaction_history_params)
        redirect_to admin_interaction_history_path(@interaction_history), notice: 'Запись о взаимодействии успешно обновлена'
      else
        load_users
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_interaction_history
      @interaction_history = InteractionHistory.find(params[:id])
    end

    def load_users
      @users = User.order(:email)
    end

    def interaction_history_params
      params.require(:interaction_history).permit(
        :user_id,
        :interaction_type,
        :subject,
        :description,
        :interaction_date,
        :follow_up_date,
        :status
      )
    end
  end
end
