# frozen_string_literal: true

class Order < ApplicationRecord
  belongs_to :user
  has_many :order_items, dependent: :destroy
  has_many :products, through: :order_items

  monetize :total_kopecks, as: :total, with_currency: :rub

  before_create :generate_order_number
  after_commit :send_paid_notification, if: :saved_change_to_paid?
  after_commit :send_completed_notification, if: :saved_change_to_completed?

  # State machine
  include AASM

  aasm column: :status do
    state :pending, initial: true
    state :processing
    state :paid
    state :completed
    state :failed
    state :refunded

    event :process do
      transitions from: :pending, to: :processing
    end

    event :pay do
      transitions from: [:pending, :processing], to: :paid, after: :grant_product_access
    end

    event :complete do
      transitions from: :paid, to: :completed
    end

    event :fail do
      transitions from: [:pending, :processing], to: :failed
    end

    event :refund do
      transitions from: [:paid, :completed], to: :refunded, after: :revoke_product_access
    end
  end

  private

  def generate_order_number
    self.order_number = "ORD-#{Time.current.to_i}-#{SecureRandom.hex(4).upcase}"
  end

  def grant_product_access
    order_items.each do |item|
      ProductAccess.find_or_create_by!(user: user, product: item.product) do |access|
        access.order = self
      end
    end
  end

  def revoke_product_access
    ProductAccess.where(order: self).destroy_all
  end

  # Notification callbacks
  def saved_change_to_paid?
    saved_change_to_status? && status == 'paid'
  end

  def send_paid_notification
    NotificationService.order_paid(user, self)
  end

  def saved_change_to_completed?
    saved_change_to_status? && status == 'completed'
  end

  def send_completed_notification
    NotificationService.order_completed(user, self)
  end
end
