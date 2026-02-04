# frozen_string_literal: true

class Wallet < ApplicationRecord
  belongs_to :user
  has_many :wallet_transactions, dependent: :destroy

  monetize :balance_kopecks, as: :balance, with_currency: :rub

  validates :balance_kopecks, numericality: { greater_than_or_equal_to: 0 }

  # Legacy methods (deprecated, use with_transaction variants)
  def deposit(amount_kopecks)
    increment!(:balance_kopecks, amount_kopecks)
  end

  def withdraw(amount_kopecks)
    return false if balance_kopecks < amount_kopecks
    decrement!(:balance_kopecks, amount_kopecks)
    true
  end

  # New transactional methods with audit trail
  def withdraw_with_transaction(amount_kopecks, order_request = nil)
    raise ArgumentError, 'Insufficient balance' unless sufficient_balance?(amount_kopecks)

    ActiveRecord::Base.transaction do
      # Lock wallet to prevent race conditions
      lock!

      balance_before = balance_kopecks
      new_balance = balance_before - amount_kopecks

      # Update balance
      update!(balance_kopecks: new_balance)

      # Create transaction record
      wallet_transactions.create!(
        transaction_type: 'withdrawal',
        amount_kopecks: -amount_kopecks,
        balance_before_kopecks: balance_before,
        balance_after_kopecks: new_balance,
        order_request: order_request,
        description: order_request ? "Оплата заявки #{order_request.request_number}" : 'Списание средств'
      )

      reload
    end
  end

  def deposit_with_transaction(amount_kopecks, external_id = nil, description = nil)
    raise ArgumentError, 'Amount must be positive' if amount_kopecks <= 0

    ActiveRecord::Base.transaction do
      # Lock wallet to prevent race conditions
      lock!

      balance_before = balance_kopecks
      new_balance = balance_before + amount_kopecks

      # Update balance
      update!(balance_kopecks: new_balance)

      # Create transaction record
      wallet_transactions.create!(
        transaction_type: 'deposit',
        amount_kopecks: amount_kopecks,
        balance_before_kopecks: balance_before,
        balance_after_kopecks: new_balance,
        external_id: external_id,
        description: description || 'Пополнение кошелька'
      )

      reload
    end
  end

  def refund_with_transaction(amount_kopecks, order_request = nil, description = nil)
    raise ArgumentError, 'Amount must be positive' if amount_kopecks <= 0

    ActiveRecord::Base.transaction do
      lock!

      balance_before = balance_kopecks
      new_balance = balance_before + amount_kopecks

      update!(balance_kopecks: new_balance)

      wallet_transactions.create!(
        transaction_type: 'refund',
        amount_kopecks: amount_kopecks,
        balance_before_kopecks: balance_before,
        balance_after_kopecks: new_balance,
        order_request: order_request,
        description: description || 'Возврат средств'
      )

      reload
    end
  end

  def sufficient_balance?(amount_kopecks)
    balance_kopecks >= amount_kopecks
  end
end
