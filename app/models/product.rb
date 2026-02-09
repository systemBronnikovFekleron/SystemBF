# frozen_string_literal: true

class Product < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  include SubRoleRestrictable

  belongs_to :category, optional: true
  has_many :order_items, dependent: :restrict_with_error
  has_many :product_accesses, dependent: :destroy
  has_many :order_requests, dependent: :restrict_with_error

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
  validate :validate_form_fields_structure

  scope :published, -> { where(status: :published) }
  scope :featured, -> { where(featured: true) }
  scope :ordered, -> { order(position: :asc, created_at: :desc) }

  def formatted_price
    price.format
  end

  def cache_key_with_version
    "#{cache_key}/#{cache_version}"
  end

  def cache_version
    updated_at.to_i
  end

  # Generate HTML form for external integration
  def external_form_html(action_url)
    FormGenerator.generate_html(self, action_url)
  end

  private

  def validate_form_fields_structure
    return if form_fields.blank?

    unless form_fields.is_a?(Array)
      errors.add(:form_fields, 'должно быть массивом')
      return
    end

    form_fields.each_with_index do |field, index|
      unless field.is_a?(Hash) && field['name'].present? && field['label'].present? && field['field_type'].present?
        errors.add(:form_fields, "поле #{index} имеет неверную структуру")
      end

      unless %w[text textarea select checkbox].include?(field['field_type'])
        errors.add(:form_fields, "поле #{index} имеет неверный тип: #{field['field_type']}")
      end
    end
  end
end
