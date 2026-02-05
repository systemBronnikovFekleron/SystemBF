# frozen_string_literal: true

class Favorite < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :favoritable, polymorphic: true

  # Validations
  validates :user_id, uniqueness: {
    scope: [:favoritable_type, :favoritable_id],
    message: 'уже добавил этот элемент в избранное'
  }

  # Scopes
  scope :ordered, -> { order(created_at: :desc) }
  scope :by_type, ->(type) { where(favoritable_type: type) }
end
