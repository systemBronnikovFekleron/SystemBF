# frozen_string_literal: true

class IntegrationLog < ApplicationRecord
  # Associations
  belongs_to :integration_setting
  belongs_to :related, polymorphic: true, optional: true

  # Validations
  validates :event_type, presence: true
  validates :status, presence: true, inclusion: {
    in: %w[success failed pending],
    message: 'должен быть одним из: success, failed, pending'
  }

  # Scopes
  scope :successful, -> { where(status: 'success') }
  scope :failed, -> { where(status: 'failed') }
  scope :pending, -> { where(status: 'pending') }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_event_type, ->(type) { where(event_type: type) }
  scope :by_integration, ->(integration_id) { where(integration_setting_id: integration_id) }
  scope :today, -> { where('created_at >= ?', Time.current.beginning_of_day) }
  scope :last_24_hours, -> { where('created_at >= ?', 24.hours.ago) }
  scope :last_7_days, -> { where('created_at >= ?', 7.days.ago) }
  scope :last_30_days, -> { where('created_at >= ?', 30.days.ago) }

  # Class methods
  def self.cleanup_old_logs(days_to_keep = 30)
    where('created_at < ?', days_to_keep.days.ago).delete_all
  end

  def self.stats_for_period(start_date, end_date)
    where(created_at: start_date..end_date).group(:status).count
  end

  # Instance methods
  def success?
    status == 'success'
  end

  def failed?
    status == 'failed'
  end

  def duration_seconds
    return nil if duration_ms.nil?
    duration_ms / 1000.0
  end
end
