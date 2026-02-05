# frozen_string_literal: true

class Initiation < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :conducted_by, class_name: 'User', optional: true

  # Enums
  enum :status, {
    pending: 0,
    completed: 1,
    passed: 2,
    failed: 3
  }, prefix: true

  # Validations
  validates :initiation_type, presence: true
  validates :level, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :status, presence: true

  # Scopes
  scope :ordered, -> { order(conducted_at: :desc, created_at: :desc) }
  scope :by_type, ->(type) { where(initiation_type: type) }
  scope :by_status, ->(status) { where(status: status) }
  scope :completed_only, -> { where(status: [:completed, :passed]) }

  # Methods
  def display_name
    "#{initiation_type} - Уровень #{level}"
  end

  def conducted?
    conducted_at.present?
  end
end
