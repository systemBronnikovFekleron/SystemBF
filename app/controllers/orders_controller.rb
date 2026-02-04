# frozen_string_literal: true

class OrdersController < ApplicationController
  before_action :authenticate_user!

  def index
    @orders = current_user.orders.order(created_at: :desc)

    respond_to do |format|
      format.html
      format.json { render json: @orders.map { |o| order_json(o) } }
    end
  end

  def show
    @order = current_user.orders.find(params[:id])

    respond_to do |format|
      format.html
      format.json { render json: order_json(@order) }
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to orders_path, alert: 'Заказ не найден'
  end

  private

  def order_json(order)
    {
      id: order.id,
      order_number: order.order_number,
      total: order.total.format,
      status: order.status,
      payment_method: order.payment_method,
      paid_at: order.paid_at,
      created_at: order.created_at,
      items: order.order_items.map do |item|
        {
          product_name: item.product.name,
          price: item.price.format,
          quantity: item.quantity,
          subtotal: (item.price * item.quantity).format
        }
      end
    }
  end
end
