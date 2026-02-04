# frozen_string_literal: true

class OrderRequestMailer < ApplicationMailer
  default from: 'noreply@bronnikov.com'

  def approved(order_request)
    @order_request = order_request
    @user = order_request.user
    @product = order_request.product

    mail(
      to: @user.email,
      subject: "Заявка #{@order_request.request_number} одобрена"
    )
  end

  def rejected(order_request)
    @order_request = order_request
    @user = order_request.user
    @product = order_request.product

    mail(
      to: @user.email,
      subject: "Заявка #{@order_request.request_number} отклонена"
    )
  end

  def insufficient_funds(order_request)
    @order_request = order_request
    @user = order_request.user
    @product = order_request.product
    @wallet = @user.wallet
    @shortfall = @order_request.total_kopecks - @wallet.balance_kopecks

    mail(
      to: @user.email,
      subject: "Пополните кошелек для завершения покупки #{@product.name}"
    )
  end

  def auto_paid(order_request)
    @order_request = order_request
    @user = order_request.user
    @product = order_request.product
    @order = order_request.order

    mail(
      to: @user.email,
      subject: "Покупка #{@product.name} успешно завершена"
    )
  end
end
