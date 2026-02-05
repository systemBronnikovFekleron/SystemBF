# frozen_string_literal: true

class EventRegistration < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :event
  belongs_to :order, optional: true

  # Enums
  enum :status, {
    pending: 0,
    confirmed: 1,
    attended: 2,
    cancelled: 3
  }, prefix: true

  # Validations
  validates :registered_at, presence: true
  validates :user_id, uniqueness: { scope: :event_id, message: 'уже зарегистрирован на это событие' }

  # Scopes
  scope :ordered, -> { order(registered_at: :desc) }
  scope :active, -> { where.not(status: :cancelled) }

  # Callbacks
  before_validation :set_registered_at, on: :create

  private

  def set_registered_at
    self.registered_at ||= Time.current
  end
end
