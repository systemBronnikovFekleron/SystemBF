class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # Pundit authorization
  include Pundit::Authorization

  # Аутентификация для web интерфейса
  helper_method :current_user, :logged_in?

  # Pundit: rescue from unauthorized access
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def current_user
    return @current_user if defined?(@current_user)

    # Сначала проверяем JWT токен в cookies (для web)
    token = cookies.encrypted[:jwt_token]

    # Если нет в cookies, проверяем Authorization header (для API)
    token ||= request.headers['Authorization']&.split(' ')&.last

    if token
      decoded = JsonWebToken.decode(token)
      @current_user = User.find_by(id: decoded[:user_id]) if decoded
    end

    # Fallback на session если JWT не работает
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]

    @current_user
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
end
