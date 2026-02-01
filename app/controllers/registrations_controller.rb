# frozen_string_literal: true

class RegistrationsController < ApplicationController

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    @user.classification = :client # По умолчанию - клиент

    if @user.save
      # Автоматический вход после регистрации
      token = JsonWebToken.encode(user_id: @user.id)

      cookies.encrypted[:jwt_token] = {
        value: token,
        expires: 24.hours.from_now,
        httponly: true,
        secure: Rails.env.production?,
        same_site: :lax
      }

      session[:user_id] = @user.id

      redirect_to dashboard_path, notice: "Регистрация успешна! Добро пожаловать, #{@user.first_name}!"
    else
      flash.now[:alert] = "Ошибка регистрации. Проверьте введенные данные."
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, :first_name, :last_name)
  end
end
