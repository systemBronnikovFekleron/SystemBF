# frozen_string_literal: true

class OrderPaymentsController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :authenticate_user!
  before_action :set_order

  def new
    # Проверяем что заказ еще не оплачен
    if @order.paid? || @order.completed?
      redirect_to @order, alert: 'Заказ уже оплачен'
      return
    end

    # Проверяем что заказ принадлежит текущему пользователю
    unless @order.user_id == current_user.id
      redirect_to root_path, alert: 'Доступ запрещен'
      return
    end
  end

  def create
    # Проверяем что заказ еще не оплачен
    if @order.paid? || @order.completed?
      redirect_to @order, alert: 'Заказ уже оплачен'
      return
    end

    # Здесь будет интеграция с CloudPayments
    # Пока просто помечаем заказ как оплаченный для тестирования
    if @order.pay!
      @order.update(paid_at: Time.current, payment_method: 'cloudpayments')

      # Предоставляем доступ к цифровым продуктам
      grant_product_access

      redirect_to @order, notice: 'Заказ успешно оплачен'
    else
      redirect_to new_order_payment_path(@order), alert: 'Ошибка при оплате заказа'
    end
  end

  private

  def set_order
    @order = Order.find(params[:order_id])
  end

  def grant_product_access
    @order.order_items.each do |item|
      product = item.product

      # Предоставляем доступ только к цифровым продуктам
      next unless %w[video_course book course].include?(product.product_type)

      ProductAccess.find_or_create_by(user: @order.user, product: product) do |access|
        access.expires_at = product.access_duration_days.days.from_now if product.access_duration_days.present?
      end
    end
  end
end
