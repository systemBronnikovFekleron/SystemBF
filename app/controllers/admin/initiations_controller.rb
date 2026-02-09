# frozen_string_literal: true

module Admin
  class InitiationsController < Admin::BaseController
    before_action :set_initiation, only: [:show, :edit, :update, :destroy]

    def index
      @initiations = Initiation.includes(:user, :conducted_by).ordered

      # Filters
      @initiations = @initiations.by_type(params[:initiation_type]) if params[:initiation_type].present?
      @initiations = @initiations.by_status(params[:status]) if params[:status].present?
      @initiations = @initiations.where(level: params[:level]) if params[:level].present?
      @initiations = @initiations.where(user_id: params[:user_id]) if params[:user_id].present?

      # Date filters
      if params[:date_from].present?
        @initiations = @initiations.where('conducted_at >= ? OR (conducted_at IS NULL AND created_at >= ?)',
                                          params[:date_from], params[:date_from])
      end
      if params[:date_to].present?
        @initiations = @initiations.where('conducted_at <= ? OR (conducted_at IS NULL AND created_at <= ?)',
                                          params[:date_to], params[:date_to])
      end

      @initiations = @initiations.page(params[:page]).per(20)

      # Stats
      @total_count = Initiation.count
      @pending_count = Initiation.status_pending.count
      @completed_count = Initiation.status_completed.count
      @passed_count = Initiation.status_passed.count
      @failed_count = Initiation.status_failed.count
    end

    def show
      @user = @initiation.user
      @granted_sub_roles = UserSubRole.where(source: @initiation).includes(:sub_role)
    end

    def new
      @initiation = Initiation.new
      @users = User.order(:last_name, :first_name)
      @conductors = User.where(classification: [:specialist, :instructor, :center_director, :manager, :admin])
                        .order(:last_name, :first_name)
      @sub_roles = SubRole.ordered
    end

    def create
      @initiation = Initiation.new(initiation_params)

      if @initiation.save
        redirect_to admin_initiation_path(@initiation), notice: 'Инициация успешно создана'
      else
        @users = User.order(:last_name, :first_name)
        @conductors = User.where(classification: [:specialist, :instructor, :center_director, :manager, :admin])
                          .order(:last_name, :first_name)
        @sub_roles = SubRole.ordered
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @users = User.order(:last_name, :first_name)
      @conductors = User.where(classification: [:specialist, :instructor, :center_director, :manager, :admin])
                        .order(:last_name, :first_name)
      @sub_roles = SubRole.ordered
    end

    def update
      if @initiation.update(initiation_params)
        redirect_to admin_initiation_path(@initiation), notice: 'Инициация успешно обновлена'
      else
        @users = User.order(:last_name, :first_name)
        @conductors = User.where(classification: [:specialist, :instructor, :center_director, :manager, :admin])
                          .order(:last_name, :first_name)
        @sub_roles = SubRole.ordered
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @initiation.destroy
      redirect_to admin_initiations_path, notice: 'Инициация удалена'
    end

    def bulk_action
      action = params[:bulk_action]
      initiation_ids = params[:initiation_ids] || []

      case action
      when 'complete'
        Initiation.where(id: initiation_ids).update_all(status: :completed, conducted_at: Time.current)
        message = "#{initiation_ids.count} инициаций отмечено как завершённые"
      when 'pass'
        Initiation.where(id: initiation_ids).update_all(status: :passed, conducted_at: Time.current)
        message = "#{initiation_ids.count} инициаций отмечено как пройденные"
      when 'fail'
        Initiation.where(id: initiation_ids).update_all(status: :failed)
        message = "#{initiation_ids.count} инициаций отмечено как непройденные"
      when 'delete'
        Initiation.where(id: initiation_ids).destroy_all
        message = "#{initiation_ids.count} инициаций удалено"
      else
        message = 'Неизвестное действие'
      end

      redirect_to admin_initiations_path, notice: message
    end

    private

    def set_initiation
      @initiation = Initiation.find(params[:id])
    end

    def initiation_params
      params.require(:initiation).permit(
        :user_id, :conducted_by_id, :initiation_type, :status,
        :level, :conducted_at, auto_grant_sub_roles: []
      )
    end
  end
end
