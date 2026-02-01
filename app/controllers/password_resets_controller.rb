# frozen_string_literal: true

class PasswordResetsController < ApplicationController
  def new
    # Страница запроса на восстановление пароля
  end

  def create
    # Обработка запроса на восстановление пароля
    # TODO: Реализовать отправку письма с инструкциями
    flash[:notice] = "Инструкции по восстановлению пароля отправлены на указанный email"
    redirect_to login_path
  end
end
