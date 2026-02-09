# frozen_string_literal: true

module Admin
  class DiagnosticsController < Admin::BaseController
    before_action :set_diagnostic, only: [:show, :edit, :update, :destroy]

    def index
      @diagnostics = Diagnostic.includes(:user, :conducted_by).ordered

      # Filters
      @diagnostics = @diagnostics.by_type(params[:diagnostic_type]) if params[:diagnostic_type].present?
      @diagnostics = @diagnostics.by_status(params[:status]) if params[:status].present?
      @diagnostics = @diagnostics.where(user_id: params[:user_id]) if params[:user_id].present?

      # Date filters
      if params[:date_from].present?
        @diagnostics = @diagnostics.where('conducted_at >= ? OR (conducted_at IS NULL AND created_at >= ?)',
                                          params[:date_from], params[:date_from])
      end
      if params[:date_to].present?
        @diagnostics = @diagnostics.where('conducted_at <= ? OR (conducted_at IS NULL AND created_at <= ?)',
                                          params[:date_to], params[:date_to])
      end

      @diagnostics = @diagnostics.page(params[:page]).per(20)

      # Stats
      @total_count = Diagnostic.count
      @scheduled_count = Diagnostic.status_scheduled.count
      @completed_count = Diagnostic.status_completed.count
      @cancelled_count = Diagnostic.status_cancelled.count
    end

    def show
      @user = @diagnostic.user
    end

    def new
      @diagnostic = Diagnostic.new
      @users = User.order(:last_name, :first_name)
      @conductors = User.where(classification: [:specialist, :instructor, :center_director, :manager, :admin])
                        .order(:last_name, :first_name)
    end

    def create
      @diagnostic = Diagnostic.new(diagnostic_params)

      if @diagnostic.save
        redirect_to admin_diagnostic_path(@diagnostic), notice: 'Диагностика успешно создана'
      else
        @users = User.order(:last_name, :first_name)
        @conductors = User.where(classification: [:specialist, :instructor, :center_director, :manager, :admin])
                          .order(:last_name, :first_name)
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @users = User.order(:last_name, :first_name)
      @conductors = User.where(classification: [:specialist, :instructor, :center_director, :manager, :admin])
                        .order(:last_name, :first_name)
    end

    def update
      if @diagnostic.update(diagnostic_params)
        redirect_to admin_diagnostic_path(@diagnostic), notice: 'Диагностика успешно обновлена'
      else
        @users = User.order(:last_name, :first_name)
        @conductors = User.where(classification: [:specialist, :instructor, :center_director, :manager, :admin])
                          .order(:last_name, :first_name)
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @diagnostic.destroy
      redirect_to admin_diagnostics_path, notice: 'Диагностика удалена'
    end

    private

    def set_diagnostic
      @diagnostic = Diagnostic.find(params[:id])
    end

    def diagnostic_params
      params.require(:diagnostic).permit(
        :user_id, :conducted_by_id, :diagnostic_type, :status,
        :conducted_at, :results, :recommendations, :score
      )
    end
  end
end
