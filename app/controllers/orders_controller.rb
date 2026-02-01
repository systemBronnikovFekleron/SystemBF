# frozen_string_literal: true

class OrdersController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :authenticate_user!, only: [:index, :create]

  def index
    @orders = current_user.orders.order(created_at: :desc)

    render json: @orders.map { |o| order_json(o) }
  end

  def show
    @order = Order.find(params[:id])

    render json: order_json(@order)
  end

  def create
    cart = Cart.new(session)

    if cart.empty?
      render json: { error: 'Корзина пуста' }, status: :unprocessable_entity
      return
    end

    @order = current_user.orders.build(
      total_kopecks: cart.total_price.cents,
      payment_method: params[:payment_method]
    )

    # Создаем order_items из корзины
    cart.items.each do |product_id, quantity|
      product = Product.find(product_id)
      @order.order_items.build(
        product: product,
        price_kopecks: product.price_kopecks,
        quantity: quantity
      )
    end

    if @order.save
      cart.clear

      case params[:payment_method]
      when 'wallet'
        process_wallet_payment
      when 'cloudpayments'
        render json: {
          message: 'Заказ создан',
          order: order_json(@order),
          redirect_to: "/orders/#{@order.id}/payment"
        }, status: :created
      else
        render json: { error: 'Неверный способ оплаты' }, status: :unprocessable_entity
      end
    else
      render json: { errors: @order.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def authenticate_user!
    token = cookies.encrypted[:jwt_token] ||
            request.headers['Authorization']&.split(' ')&.last

    if token
      decoded = JsonWebToken.decode(token)
      @current_user = User.find_by(id: decoded[:user_id]) if decoded
    end

    render json: { error: 'Unauthorized' }, status: :unauthorized unless @current_user
  end

  def current_user
    @current_user
  end

  def process_wallet_payment
    if current_user.wallet.withdraw(@order.total_kopecks)
      @order.pay!
      @order.update(paid_at: Time.current, payment_method: 'wallet')
      render json: {
        message: 'Заказ оплачен из кошелька',
        order: order_json(@order)
      }, status: :ok
    else
      @order.fail!
      render json: { error: 'Недостаточно средств в кошельке' }, status: :unprocessable_entity
    end
  end

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
