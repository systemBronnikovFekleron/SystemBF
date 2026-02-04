# frozen_string_literal: true

class PasswordResetsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:create, :update]

  def new
    # Форма ввода email
  end

  def create
    @user = User.find_by(email: params[:email]&.downcase)

    if @user
      @user.create_reset_password_token!
      UserMailer.password_reset(@user, @user.reset_password_token).deliver_later
      redirect_to root_path, notice: 'Инструкции по восстановлению пароля отправлены на ваш email'
    else
      flash.now[:alert] = 'Email не найден'
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @user = User.find_by(reset_password_token: params[:token])

    if @user.nil?
      redirect_to root_path, alert: 'Неверная ссылка для восстановления пароля'
    elsif @user.reset_password_token_expired?
      redirect_to root_path, alert: 'Ссылка для восстановления пароля истекла. Запросите новую.'
    end
  end

  def update
    @user = User.find_by(reset_password_token: params[:token])

    if @user.nil?
      redirect_to root_path, alert: 'Неверная ссылка для восстановления пароля'
      return
    end

    if @user.reset_password_token_expired?
      redirect_to root_path, alert: 'Ссылка для восстановления пароля истекла. Запросите новую.'
      return
    end

    if params[:password].blank?
      flash.now[:alert] = 'Пароль не может быть пустым'
      render :edit, status: :unprocessable_entity
      return
    end

    if params[:password] != params[:password_confirmation]
      flash.now[:alert] = 'Пароли не совпадают'
      render :edit, status: :unprocessable_entity
      return
    end

    if @user.update(password: params[:password], password_confirmation: params[:password_confirmation])
      @user.clear_reset_password_token!
      redirect_to login_path, notice: 'Пароль успешно изменен. Войдите с новым паролем.'
    else
      flash.now[:alert] = @user.errors.full_messages.join(', ')
      render :edit, status: :unprocessable_entity
    end
  end
end
