# frozen_string_literal: true

class Wallet < ApplicationRecord
  belongs_to :user

  monetize :balance_kopecks, as: :balance, with_currency: :rub

  validates :balance_kopecks, numericality: { greater_than_or_equal_to: 0 }

  def deposit(amount_kopecks)
    increment!(:balance_kopecks, amount_kopecks)
  end

  def withdraw(amount_kopecks)
    return false if balance_kopecks < amount_kopecks
    decrement!(:balance_kopecks, amount_kopecks)
    true
  end
end
