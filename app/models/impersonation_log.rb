# frozen_string_literal: true

class ImpersonationLog < ApplicationRecord
  belongs_to :admin, class_name: 'User'
  belongs_to :user, class_name: 'User'

  validates :session_token, presence: true, uniqueness: true
  validates :started_at, presence: true

  scope :active, -> { where(ended_at: nil) }
  scope :ended, -> { where.not(ended_at: nil) }
  scope :recent, -> { order(started_at: :desc) }

  before_validation :set_started_at, on: :create
  before_validation :generate_session_token, on: :create

  # Константы
  MAX_DURATION_HOURS = 4

  def active?
    ended_at.nil? && !expired?
  end

  def expired?
    started_at + MAX_DURATION_HOURS.hours < Time.current
  end

  def duration_seconds
    return nil if ended_at.nil?
    (ended_at - started_at).to_i
  end

  def duration_human
    return 'Активна' if ended_at.nil?
    ActionController::Base.helpers.distance_of_time_in_words(started_at, ended_at)
  end

  def end_session!
    update!(ended_at: Time.current)
  end

  private

  def set_started_at
    self.started_at ||= Time.current
  end

  def generate_session_token
    self.session_token ||= SecureRandom.uuid
  end
end
