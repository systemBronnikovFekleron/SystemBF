# frozen_string_literal: true

class Diagnostic < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :conducted_by, class_name: 'User', optional: true

  # Enums
  enum :status, {
    scheduled: 0,
    completed: 1,
    cancelled: 2
  }, prefix: true

  # Validations
  validates :diagnostic_type, presence: true
  validates :status, presence: true

  # Scopes
  scope :ordered, -> { order(conducted_at: :desc, created_at: :desc) }
  scope :by_type, ->(type) { where(diagnostic_type: type) }
  scope :by_status, ->(status) { where(status: status) }
  scope :completed_only, -> { where(status: :completed) }

  # Methods
  def display_name
    case diagnostic_type
    when 'vision'
      'Диагностика: Видение'
    when 'bioenergy'
      'Диагностика: Биоэнергетика'
    when 'psychobiocomputer'
      'Диагностика: Психобиокомпьютер'
    else
      "Диагностика: #{diagnostic_type}"
    end
  end

  def conducted?
    conducted_at.present?
  end

  def has_recommendations?
    recommendations.present?
  end
end
