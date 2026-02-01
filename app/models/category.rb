# frozen_string_literal: true

class Category < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  has_many :products, dependent: :nullify

  validates :name, presence: true, uniqueness: true

  scope :ordered, -> { order(position: :asc) }
end
