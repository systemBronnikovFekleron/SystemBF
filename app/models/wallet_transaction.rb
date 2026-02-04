# frozen_string_literal: true

class WalletTransaction < ApplicationRecord
  # Associations
  belongs_to :wallet
  belongs_to :order_request, optional: true

  # Enums
  enum :transaction_type, { deposit: 'deposit', withdrawal: 'withdrawal', refund: 'refund' }, prefix: true

  # Validations
  validates :transaction_type, presence: true
  validates :amount_kopecks, presence: true, numericality: { other_than: 0 }
  validates :balance_before_kopecks, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :balance_after_kopecks, presence: true, numericality: { greater_than_or_equal_to: 0 }

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :for_wallet, ->(wallet_id) { where(wallet_id: wallet_id) }

  # Money integration
  def amount
    Money.new(amount_kopecks.abs, 'RUB')
  end

  def balance_before
    Money.new(balance_before_kopecks, 'RUB')
  end

  def balance_after
    Money.new(balance_after_kopecks, 'RUB')
  end
end
