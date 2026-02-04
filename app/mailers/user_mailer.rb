# frozen_string_literal: true

class UserMailer < ApplicationMailer
  default from: 'noreply@bronnikov.com'

  def welcome_email(user)
    @user = user
    mail(to: @user.email, subject: 'Добро пожаловать в Систему Бронникова!')
  end

  def order_confirmation(order)
    @order = order
    @user = order.user
    @items = order.order_items.includes(:product)

    mail(
      to: @user.email,
      subject: "Заказ ##{@order.order_number} создан"
    )
  end

  def payment_received(order)
    @order = order
    @user = order.user
    @items = order.order_items.includes(:product)

    mail(
      to: @user.email,
      subject: "Оплата заказа ##{@order.order_number} получена"
    )
  end

  def product_access_granted(product_access)
    @product_access = product_access
    @user = product_access.user
    @product = product_access.product

    mail(
      to: @user.email,
      subject: "Доступ к #{@product.name} открыт!"
    )
  end

  def password_reset(user, token)
    @user = user
    @token = token
    @reset_url = edit_password_reset_url(token: @token, host: ENV.fetch('APP_HOST', 'localhost:3000'))

    mail(
      to: @user.email,
      subject: 'Восстановление пароля - Система Бронникова'
    )
  end

  def welcome_external_form(user, password)
    @user = user
    @password = password
    @login_url = login_url(host: ENV.fetch('APP_HOST', 'localhost:3000'))

    mail(
      to: @user.email,
      subject: 'Ваш аккаунт в Системе Бронникова'
    )
  end
end
