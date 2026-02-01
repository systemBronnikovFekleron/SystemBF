# frozen_string_literal: true

class Cart
  attr_reader :items

  def initialize(session)
    @session = session
    @items = load_items
  end

  def add_product(product_id, quantity = 1)
    product_id = product_id.to_s
    @items[product_id] ||= 0
    @items[product_id] += quantity
    save_items
  end

  def remove_product(product_id)
    @items.delete(product_id.to_s)
    save_items
  end

  def update_quantity(product_id, quantity)
    product_id = product_id.to_s
    if quantity > 0
      @items[product_id] = quantity
    else
      @items.delete(product_id)
    end
    save_items
  end

  def total_price
    return Money.new(0, 'RUB') if @items.empty?

    products = Product.where(id: @items.keys)
    total_kopecks = products.sum { |p| p.price_kopecks * @items[p.id.to_s] }
    Money.new(total_kopecks, 'RUB')
  end

  def clear
    @items = {}
    save_items
  end

  def empty?
    @items.empty?
  end

  def count
    @items.values.sum
  end

  private

  def load_items
    @session[:cart_items] || {}
  end

  def save_items
    @session[:cart_items] = @items
  end
end
