# frozen_string_literal: true

class ProductAccess < ApplicationRecord
  belongs_to :user
  belongs_to :product
  belongs_to :order

  after_create :send_access_granted_notification

  scope :active, -> { where('expires_at IS NULL OR expires_at > ?', Time.current) }

  def active?
    expires_at.nil? || expires_at > Time.current
  end

  private

  def send_access_granted_notification
    NotificationService.product_access_granted(user, product)
  end
end
