# frozen_string_literal: true

class CartsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def show
    cart = Cart.new(session)

    render json: {
      items: cart_items_json(cart),
      total_price: cart.total_price.format,
      count: cart.count
    }
  end

  def add_item
    cart = Cart.new(session)
    product = Product.find(params[:product_id])

    cart.add_product(product.id, params[:quantity]&.to_i || 1)

    render json: {
      message: 'Товар добавлен в корзину',
      count: cart.count
    }, status: :ok
  end

  def remove_item
    cart = Cart.new(session)
    cart.remove_product(params[:product_id])

    render json: {
      message: 'Товар удален из корзины',
      count: cart.count
    }, status: :ok
  end

  def update
    cart = Cart.new(session)
    cart.update_quantity(params[:product_id], params[:quantity].to_i)

    render json: {
      message: 'Корзина обновлена',
      count: cart.count
    }, status: :ok
  end

  def destroy
    cart = Cart.new(session)
    cart.clear

    render json: { message: 'Корзина очищена' }, status: :ok
  end

  private

  def cart_items_json(cart)
    products = Product.where(id: cart.items.keys)

    products.map do |product|
      {
        product_id: product.id,
        name: product.name,
        price: product.price.format,
        quantity: cart.items[product.id.to_s],
        subtotal: (product.price * cart.items[product.id.to_s]).format
      }
    end
  end
end
