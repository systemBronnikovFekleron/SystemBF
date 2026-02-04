# frozen_string_literal: true

class IntegrationStatistic < ApplicationRecord
  # Associations
  belongs_to :integration_setting

  # Validations
  validates :date, presence: true
  validates :period_type, presence: true, inclusion: {
    in: %w[daily weekly monthly],
    message: 'должен быть одним из: daily, weekly, monthly'
  }
  validates :date, uniqueness: { scope: [:integration_setting_id, :period_type] }

  # Scopes
  scope :daily, -> { where(period_type: 'daily') }
  scope :weekly, -> { where(period_type: 'weekly') }
  scope :monthly, -> { where(period_type: 'monthly') }
  scope :for_period, ->(start_date, end_date) { where(date: start_date..end_date) }
  scope :recent, ->(limit = 30) { order(date: :desc).limit(limit) }

  # Callbacks
  before_save :calculate_success_rate

  # Class methods
  def self.aggregate_from_logs(integration_setting_id, date, period_type = 'daily')
    integration_setting = IntegrationSetting.find(integration_setting_id)
    date_range = case period_type
                 when 'daily'
                   date.beginning_of_day..date.end_of_day
                 when 'weekly'
                   date.beginning_of_week..date.end_of_week
                 when 'monthly'
                   date.beginning_of_month..date.end_of_month
                 end

    logs = integration_setting.integration_logs.where(created_at: date_range)
    total = logs.count
    successful = logs.successful.count
    failed = logs.failed.count
    avg_duration = logs.where.not(duration_ms: nil).average(:duration_ms)&.to_i

    find_or_initialize_by(
      integration_setting_id: integration_setting_id,
      date: date,
      period_type: period_type
    ).tap do |stat|
      stat.total_requests = total
      stat.successful_requests = successful
      stat.failed_requests = failed
      stat.avg_duration_ms = avg_duration
      stat.save!
    end
  end

  # Instance methods
  def success_rate_percentage
    return 0 if total_requests.zero?
    ((successful_requests.to_f / total_requests) * 100).round(2)
  end

  def failure_rate_percentage
    return 0 if total_requests.zero?
    ((failed_requests.to_f / total_requests) * 100).round(2)
  end

  def avg_duration_seconds
    return nil if avg_duration_ms.nil?
    avg_duration_ms / 1000.0
  end

  private

  def calculate_success_rate
    self.success_rate = success_rate_percentage if total_requests.positive?
  end
end
