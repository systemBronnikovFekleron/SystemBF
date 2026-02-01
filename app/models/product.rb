# frozen_string_literal: true

class Product < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  belongs_to :category, optional: true
  has_many :order_items, dependent: :restrict_with_error
  has_many :product_accesses, dependent: :destroy

  monetize :price_kopecks, as: :price, with_currency: :rub

  # State machine для статусов
  include AASM

  aasm column: :status do
    state :draft, initial: true
    state :published
    state :archived

    event :publish do
      transitions from: :draft, to: :published
    end

    event :archive do
      transitions from: [:draft, :published], to: :archived
    end

    event :unarchive do
      transitions from: :archived, to: :draft
    end
  end

  enum :product_type, {
    video: 'video',
    book: 'book',
    course: 'course',
    service: 'service',
    event_access: 'event_access'
  }

  validates :name, presence: true
  validates :price_kopecks, numericality: { greater_than: 0 }
  validates :product_type, presence: true

  scope :published, -> { where(status: :published) }
  scope :featured, -> { where(featured: true) }
  scope :ordered, -> { order(position: :asc, created_at: :desc) }
end
