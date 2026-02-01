# frozen_string_literal: true

class SessionsController < ApplicationController

  def new
    # Login page
  end

  def create
    user = User.find_by(email: params[:email]&.downcase)

    if user&.authenticate(params[:password])
      # Обновить last_login данные
      user.update(last_login_at: Time.current, last_login_ip: request.remote_ip)

      token = JsonWebToken.encode(user_id: user.id)

      # Установка JWT в httpOnly cookie
      cookies.encrypted[:jwt_token] = {
        value: token,
        expires: 24.hours.from_now,
        httponly: true,
        secure: Rails.env.production?,
        same_site: :lax
      }

      # Установить простую session для helpers
      session[:user_id] = user.id

      redirect_to dashboard_path, notice: "Добро пожаловать, #{user.first_name}!"
    else
      flash.now[:alert] = "Неверный email или пароль"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    cookies.delete(:jwt_token)
    session.delete(:user_id)
    redirect_to root_path, notice: "Вы вышли из системы"
  end
end
