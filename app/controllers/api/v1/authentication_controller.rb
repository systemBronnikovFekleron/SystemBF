# frozen_string_literal: true

module Api
  module V1
    class AuthenticationController < BaseController
      skip_before_action :authenticate_request, only: [:login, :logout]

      def login
        user = User.find_by(email: params[:email]&.downcase)

        if user&.authenticate(params[:password])
          # Обновить last_login данные
          user.update(last_login_at: Time.current, last_login_ip: request.remote_ip)

          token = JsonWebToken.encode(user_id: user.id)

          # Установка JWT в httpOnly cookie для WordPress
          cookies.encrypted[:jwt_token] = {
            value: token,
            expires: 24.hours.from_now,
            httponly: true,
            secure: Rails.env.production?,
            same_site: :lax
          }

          render json: {
            token: token,
            user: user_data(user)
          }, status: :ok
        else
          render json: { error: 'Invalid credentials' }, status: :unauthorized
        end
      end

      def logout
        cookies.delete(:jwt_token)
        render json: { message: 'Logged out successfully' }
      end

      def validate_token
        # Endpoint для WordPress плагина
        if @current_user
          render json: {
            valid: true,
            user: user_data(@current_user)
          }
        else
          render json: { valid: false }, status: :unauthorized
        end
      end

      private

      def user_data(user)
        {
          id: user.id,
          email: user.email,
          first_name: user.first_name,
          last_name: user.last_name,
          classification: user.classification,
          active: user.active
        }
      end
    end
  end
end
