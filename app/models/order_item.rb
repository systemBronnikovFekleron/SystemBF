# frozen_string_literal: true

class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :product

  monetize :price_kopecks, as: :price, with_currency: :rub

  validates :quantity, numericality: { greater_than: 0 }
end
