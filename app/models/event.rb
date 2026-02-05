# frozen_string_literal: true

class Event < ApplicationRecord
  extend FriendlyId
  include SubRoleRestrictable

  # FriendlyId
  friendly_id :title, use: :slugged

  # Associations
  belongs_to :category, optional: true
  belongs_to :organizer, class_name: 'User', optional: true
  has_many :event_registrations, dependent: :destroy
  has_many :registered_users, through: :event_registrations, source: :user

  # Enums
  enum :status, {
    draft: 0,
    published: 1,
    cancelled: 2,
    completed: 3
  }, prefix: true

  # Validations
  validates :title, presence: true
  validates :starts_at, presence: true
  validates :price_kopecks, numericality: { greater_than_or_equal_to: 0 }
  validates :max_participants, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true

  # Scopes
  scope :published, -> { where(status: :published) }
  scope :upcoming, -> { where('starts_at > ?', Time.current) }
  scope :past, -> { where('starts_at <= ?', Time.current) }
  scope :ordered, -> { order(starts_at: :asc) }
  scope :online, -> { where(is_online: true) }
  scope :offline, -> { where(is_online: false) }

  # Money
  def price
    Money.new(price_kopecks, 'RUB')
  end

  # Methods
  def free?
    price_kopecks.zero?
  end

  def paid?
    price_kopecks > 0
  end

  def full?
    return false if max_participants.nil?

    confirmed_registrations_count >= max_participants
  end

  def confirmed_registrations_count
    event_registrations.where(status: :confirmed).count
  end

  def available_spots
    return nil if max_participants.nil?

    max_participants - confirmed_registrations_count
  end

  def past?
    starts_at <= Time.current
  end

  def upcoming?
    starts_at > Time.current
  end

  def format_location
    is_online? ? 'Онлайн' : location
  end
end
