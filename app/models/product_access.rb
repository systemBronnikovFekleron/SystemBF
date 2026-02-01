# frozen_string_literal: true

class ProductAccess < ApplicationRecord
  belongs_to :user
  belongs_to :product
  belongs_to :order

  scope :active, -> { where('expires_at IS NULL OR expires_at > ?', Time.current) }

  def active?
    expires_at.nil? || expires_at > Time.current
  end
end
