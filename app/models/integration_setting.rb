# frozen_string_literal: true

class IntegrationSetting < ApplicationRecord
  # Associations
  belongs_to :created_by, class_name: 'User', optional: true
  belongs_to :updated_by, class_name: 'User', optional: true
  has_many :integration_logs, dependent: :destroy
  has_many :integration_statistics, dependent: :destroy

  # Encryption
  encrypts :encrypted_credentials

  # Validations
  validates :integration_type, presence: true, uniqueness: true
  validates :integration_type, inclusion: {
    in: %w[email telegram google_analytics cloudpayments],
    message: 'должен быть одним из: email, telegram, google_analytics, cloudpayments'
  }
  validates :name, presence: true
  validates :last_test_status, inclusion: {
    in: %w[success failed pending],
    allow_nil: true
  }

  # Scopes
  scope :enabled, -> { where(enabled: true) }
  scope :disabled, -> { where(enabled: false) }
  scope :recently_used, -> { where.not(last_used_at: nil).order(last_used_at: :desc) }
  scope :healthy, -> { where(last_test_status: 'success') }
  scope :unhealthy, -> { where(last_test_status: 'failed') }

  # Callbacks
  after_update :clear_credentials_cache, if: :saved_change_to_encrypted_credentials?

  # Enable/Disable methods
  def enable!
    update!(enabled: true)
    log_event('integration_enabled', 'success', 'Интеграция включена')
  end

  def disable!
    update!(enabled: false)
    log_event('integration_disabled', 'success', 'Интеграция выключена')
  end

  # Health check
  def healthy?
    last_test_status == 'success' && last_test_at.present? && last_test_at > 1.day.ago
  end

  # Credentials management
  def credentials_hash
    Rails.cache.fetch("integration_#{id}/credentials", expires_in: 5.minutes) do
      return {} if encrypted_credentials.blank?
      begin
        JSON.parse(encrypted_credentials).with_indifferent_access
      rescue JSON::ParserError
        {}
      end
    end
  end

  def update_credentials!(new_credentials)
    self.encrypted_credentials = new_credentials.to_json
    save!
    log_event('credentials_updated', 'success', 'API ключи обновлены')
  end

  # Test connection
  def test_connection
    return { success: false, message: 'Интеграция отключена' } unless enabled

    start_time = Time.current
    result = perform_test_connection
    duration = ((Time.current - start_time) * 1000).to_i

    update_columns(
      last_test_at: Time.current,
      last_test_status: result[:success] ? 'success' : 'failed',
      last_test_message: result[:message]
    )

    log_event('test_connection', result[:success] ? 'success' : 'failed',
              result[:message], duration_ms: duration)

    result
  rescue StandardError => e
    update_columns(
      last_test_at: Time.current,
      last_test_status: 'failed',
      last_test_message: e.message
    )

    log_event('test_connection', 'failed', e.message, error_details: e.backtrace.join("\n"))

    { success: false, message: "Ошибка: #{e.message}" }
  end

  # Increment usage
  def increment_usage!
    increment!(:usage_count)
    touch(:last_used_at)
  end

  # Masked credentials for UI
  def masked_credentials
    creds = credentials_hash
    return {} if creds.empty?

    creds.transform_values do |value|
      next value if value.blank? || value.length < 8
      "#{value[0..3]}...#{value[-3..]}"
    end
  end

  private

  def perform_test_connection
    service_class = "IntegrationServices::#{integration_type.camelize}Service".constantize
    service_class.test_connection(credentials_hash, settings)
  rescue NameError
    { success: false, message: 'Сервис интеграции не найден' }
  end

  def log_event(event_type, status, message, metadata = {})
    integration_logs.create!(
      event_type: event_type,
      status: status,
      message: message,
      metadata: metadata.merge(settings: settings),
      error_details: metadata[:error_details]
    )
  end

  def clear_credentials_cache
    Rails.cache.delete("integration_#{id}/credentials")
  end
end
