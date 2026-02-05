# frozen_string_literal: true

class OrderRequest < ApplicationRecord
  include AASM

  # Associations
  belongs_to :user
  belongs_to :product
  belongs_to :order, optional: true
  belongs_to :approved_by, class_name: 'User', optional: true
  has_many :wallet_transactions, dependent: :nullify

  # Validations
  validates :request_number, uniqueness: true, allow_blank: true
  validates :total_kopecks, numericality: { greater_than: 0 }, allow_nil: true
  validates :status, presence: true
  validates :rejection_reason, presence: true, if: -> { status == 'rejected' }

  # Callbacks
  before_create :generate_request_number
  before_create :set_total_from_product
  after_create :send_created_notification
  after_save :auto_complete_if_paid, if: :should_auto_complete?
  after_commit :process_auto_payment_after_approve, if: :saved_change_to_approved?
  after_commit :send_approved_notification, if: :saved_change_to_approved?
  after_commit :send_rejected_notification, if: :saved_change_to_rejected?
  after_commit :send_paid_notification, if: :saved_change_to_paid?

  # AASM State Machine
  aasm column: :status do
    state :pending, initial: true
    state :approved
    state :rejected
    state :paid
    state :completed
    state :cancelled

    event :approve do
      transitions from: :pending, to: :approved, after: :set_approved_timestamp
    end

    event :reject do
      transitions from: :pending, to: :rejected, after: :set_rejected_timestamp
    end

    event :pay do
      transitions from: :approved, to: :paid, after: [:set_paid_timestamp, :create_order_and_grant_access]
    end

    event :complete do
      transitions from: :paid, to: :completed
    end

    event :cancel do
      transitions from: [:pending, :approved], to: :cancelled
    end
  end

  # Money integration
  def total
    Money.new(total_kopecks, 'RUB')
  end

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :pending_approval, -> { where(status: 'pending') }
  scope :approved_pending_payment, -> { where(status: 'approved') }

  private

  def generate_request_number
    timestamp = Time.current.to_i
    random_hex = SecureRandom.hex(4).upcase
    self.request_number = "REQ-#{timestamp}-#{random_hex}"
  end

  def set_total_from_product
    self.total_kopecks = product.price_kopecks if total_kopecks.blank?
  end

  def set_approved_timestamp
    self.approved_at = Time.current
  end

  def set_rejected_timestamp
    self.rejected_at = Time.current
  end

  def set_paid_timestamp
    self.paid_at = Time.current
    self.payment_method = 'wallet'
  end

  def process_auto_payment
    # Reload product to get latest auto_approve value
    product.reload
    return unless product.auto_approve
    return unless user.wallet.sufficient_balance?(total_kopecks)

    begin
      user.wallet.withdraw_with_transaction(total_kopecks, self)
      pay! # Trigger paid event
    rescue StandardError => e
      Rails.logger.error "Auto-payment failed for OrderRequest #{id}: #{e.message}"
      # Send notification to user about insufficient funds
      OrderRequestMailer.insufficient_funds(self).deliver_later
    end
  end

  def create_order_and_grant_access
    ActiveRecord::Base.transaction do
      # Create Order
      new_order = Order.create!(
        user: user,
        total_kopecks: total_kopecks,
        status: 'paid'
      )

      # Create OrderItem
      OrderItem.create!(
        order: new_order,
        product: product,
        price_kopecks: total_kopecks,
        quantity: 1
      )

      # Grant ProductAccess
      ProductAccess.create!(
        user: user,
        product: product,
        order: new_order
      )

      # Auto-grant SubRoles if configured
      if product.auto_grant_sub_roles.present?
        user.grant_sub_roles!(
          product.auto_grant_sub_roles,
          granted_by: nil,
          granted_via: 'product_purchase',
          source: product
        )
        Rails.logger.info "Auto-granted sub_roles #{product.auto_grant_sub_roles} to user #{user.id} via product #{product.id}"
      end

      # Link OrderRequest to Order (skip callbacks to avoid recursion)
      update_column(:order_id, new_order.id)
      self.order = new_order
      # Set flag for auto_complete callback
      @should_auto_complete = true
    end
  rescue StandardError => e
    Rails.logger.error "Failed to create order for OrderRequest #{id}: #{e.message}"
    raise
  end

  def should_auto_complete?
    @should_auto_complete && status == 'paid' && order.present?
  end

  def auto_complete_if_paid
    complete! if may_complete?
    @should_auto_complete = false
  end

  def saved_change_to_approved?
    saved_change_to_status? && status == 'approved'
  end

  def process_auto_payment_after_approve
    # This runs after commit, so status is already 'approved' in DB
    process_auto_payment
  end

  # Notification callbacks
  def send_created_notification
    NotificationService.order_request_created(user, self)
  end

  def send_approved_notification
    NotificationService.order_request_approved(user, self)
  end

  def saved_change_to_rejected?
    saved_change_to_status? && status == 'rejected'
  end

  def send_rejected_notification
    NotificationService.order_request_rejected(user, self, reason: rejection_reason)
  end

  def saved_change_to_paid?
    saved_change_to_status? && status == 'paid'
  end

  def send_paid_notification
    NotificationService.order_request_paid(user, self)
  end
end
