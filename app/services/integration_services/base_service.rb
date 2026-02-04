# frozen_string_literal: true

module IntegrationServices
  class BaseService
    class << self
      # Get integration setting from database
      def integration_setting
        @integration_setting ||= IntegrationSetting.find_by(integration_type: integration_type_key)
      end

      # Check if integration is enabled
      def enabled?
        integration_setting&.enabled? || false
      end

      # Get credentials with fallback to Rails credentials
      def credentials
        return {} unless integration_setting

        # Try database first
        db_credentials = integration_setting.credentials_hash
        return db_credentials if db_credentials.present?

        # Fallback to Rails credentials
        rails_credentials_fallback
      end

      # Get settings from database
      def settings
        integration_setting&.settings || {}
      end

      # Wrapper for logging integration events
      def with_logging(event_type, metadata = {})
        return yield unless integration_setting

        start_time = Time.current
        result = nil
        status = 'success'
        error_details = nil

        begin
          result = yield
        rescue StandardError => e
          status = 'failed'
          error_details = "#{e.class}: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
          raise
        ensure
          duration = ((Time.current - start_time) * 1000).to_i

          integration_setting.integration_logs.create!(
            event_type: event_type,
            status: status,
            message: log_message_from_result(result, status),
            metadata: metadata,
            error_details: error_details,
            duration_ms: duration
          )

          integration_setting.increment_usage! if status == 'success'
        end

        result
      end

      # Test connection - must be implemented by subclasses
      def test_connection(credentials, settings)
        raise NotImplementedError, "#{self.class.name} must implement test_connection"
      end

      private

      # Integration type key - must be implemented by subclasses
      def integration_type_key
        raise NotImplementedError, "#{self.class.name} must implement integration_type_key"
      end

      # Fallback to Rails credentials - must be implemented by subclasses
      def rails_credentials_fallback
        {}
      end

      # Generate log message from result
      def log_message_from_result(result, status)
        return 'Операция выполнена успешно' if status == 'success'
        'Операция завершилась с ошибкой'
      end
    end
  end
end
