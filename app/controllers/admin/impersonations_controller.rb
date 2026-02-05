# frozen_string_literal: true

module Admin
  class ImpersonationsController < BaseController
    before_action :set_user, only: [:create]
    before_action :prevent_self_impersonation, only: [:create]
    before_action :prevent_admin_impersonation, only: [:create]

    def index
      @active_sessions = ImpersonationLog.active.includes(:admin, :user).recent.page(params[:page]).per(20)
      @recent_sessions = ImpersonationLog.ended.includes(:admin, :user).recent.page(params[:recent_page]).per(20)
      @stats = {
        active_count: ImpersonationLog.active.count,
        today_count: ImpersonationLog.where('started_at >= ?', Time.current.beginning_of_day).count,
        total_count: ImpersonationLog.count
      }
    end

    def create
      # Завершить все активные сессии имперсонации для этого админа
      ImpersonationLog.active.where(admin: current_user).find_each(&:end_session!)

      # Создать новую сессию имперсонации
      @impersonation_log = ImpersonationLog.create!(
        admin: current_user,
        user: @user,
        ip_address: request.remote_ip,
        user_agent: request.user_agent,
        reason: params[:reason]
      )

      # Создать JWT токен с метаданными имперсонации
      payload = {
        user_id: @user.id,
        impersonator_id: current_user.id,
        impersonation_session_token: @impersonation_log.session_token,
        exp: (Time.current + ImpersonationLog::MAX_DURATION_HOURS.hours).to_i
      }
      token = JsonWebToken.encode(payload)

      # Сохранить токен в cookies
      cookies.encrypted[:jwt_token] = {
        value: token,
        httponly: true,
        secure: Rails.env.production?,
        expires: ImpersonationLog::MAX_DURATION_HOURS.hours.from_now
      }

      redirect_to dashboard_path, notice: "Вы вошли как #{@user.email}. Сессия истекает через 4 часа."
    end

    def destroy
      impersonation_log = current_impersonation
      return redirect_to dashboard_path, alert: 'Сессия имперсонации не найдена' if impersonation_log.nil?

      # Завершить сессию имперсонации
      impersonation_log.end_session!

      # Восстановить токен админа
      admin = impersonation_log.admin
      payload = { user_id: admin.id, exp: 24.hours.from_now.to_i }
      token = JsonWebToken.encode(payload)

      cookies.encrypted[:jwt_token] = {
        value: token,
        httponly: true,
        secure: Rails.env.production?,
        expires: 24.hours.from_now
      }

      redirect_to admin_user_path(impersonation_log.user), notice: 'Сессия имперсонации завершена'
    end

    def show
      @impersonation_log = ImpersonationLog.find(params[:id])
    end

    private

    def set_user
      @user = User.find(params[:user_id])
    end

    def prevent_self_impersonation
      return unless @user.id == current_user.id
      redirect_to admin_user_path(@user), alert: 'Нельзя войти за самого себя'
    end

    def prevent_admin_impersonation
      return unless @user.admin_role?
      redirect_to admin_user_path(@user), alert: 'Нельзя войти за другого администратора'
    end
  end
end
