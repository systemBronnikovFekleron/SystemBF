class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # Pundit authorization
  include Pundit::Authorization

  # Аутентификация для web интерфейса
  helper_method :current_user, :logged_in?, :impersonating?, :real_admin_user, :current_impersonation

  # Pundit: rescue from unauthorized access
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  # Автоматически использовать dashboard layout для авторизованных пользователей
  layout :layout_by_authentication

  private

  def current_user
    return @current_user if defined?(@current_user)

    # Сначала проверяем JWT токен в cookies (для web)
    token = cookies.encrypted[:jwt_token]

    # Если нет в cookies, проверяем Authorization header (для API)
    token ||= request.headers['Authorization']&.split(' ')&.last

    if token
      decoded = JsonWebToken.decode(token)

      if decoded
        # Проверить наличие метаданных имперсонации
        if decoded[:impersonator_id].present?
          # Это сессия имперсонации
          impersonation_log = ImpersonationLog.find_by(session_token: decoded[:impersonation_session_token])

          # Проверить активность сессии
          if impersonation_log.nil? || !impersonation_log.active?
            # Сессия истекла или не найдена - очистить cookies
            cookies.delete(:jwt_token)
            return nil
          end

          @current_impersonation = impersonation_log
          @current_user = User.find_by(id: decoded[:user_id])
        else
          # Обычная сессия
          @current_user = User.find_by(id: decoded[:user_id])
        end
      end
    end

    # Fallback на session если JWT не работает
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]

    @current_user
  rescue JWT::DecodeError, ActiveRecord::RecordNotFound
    nil
  end

  def impersonating?
    current_user.present? && current_impersonation.present?
  end

  def real_admin_user
    return nil unless impersonating?
    current_impersonation.admin
  end

  def current_impersonation
    current_user # Ensure current_user is set
    @current_impersonation
  end

  # Блокировка доступа в админку во время имперсонации
  def block_admin_during_impersonation
    return unless impersonating?
    redirect_to dashboard_path, alert: 'Во время имперсонации доступ в админку заблокирован. Завершите сессию.'
  end

  def logged_in?
    current_user.present?
  end

  def authenticate_user!
    return if logged_in?

    respond_to do |format|
      format.html { redirect_to login_path, alert: 'Пожалуйста, войдите в систему' }
      format.json { render json: { error: 'Unauthorized' }, status: :unauthorized }
    end
  end

  def user_not_authorized
    respond_to do |format|
      format.html do
        flash[:alert] = 'У вас нет прав для выполнения этого действия.'
        redirect_back(fallback_location: root_path)
      end
      format.json { render json: { error: 'Forbidden' }, status: :forbidden }
    end
  end

  def layout_by_authentication
    # Исключения: страницы входа/регистрации всегда используют application layout
    return 'application' if controller_name == 'sessions' || controller_name == 'registrations' || controller_name == 'password_resets'

    # Для авторизованных пользователей - dashboard layout
    logged_in? ? 'dashboard' : 'application'
  end
end
