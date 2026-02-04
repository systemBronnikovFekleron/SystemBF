# frozen_string_literal: true

module IntegrationServices
  class GoogleAnalyticsService < BaseService
    class << self
      def test_connection(credentials, settings = {})
        measurement_id = credentials['measurement_id'] || credentials[:measurement_id]

        return missing_credentials_error unless measurement_id

        # Google Analytics не требует проверки подключения через API
        # Просто валидируем формат measurement_id
        if measurement_id.match?(/^G-[A-Z0-9]+$/)
          {
            success: true,
            message: "Google Analytics 4 настроен: #{measurement_id}"
          }
        else
          {
            success: false,
            message: 'Неверный формат Measurement ID (ожидается G-XXXXXXXXXX)'
          }
        end
      end

      # Track event via Measurement Protocol (GA4)
      def track_event(client_id:, event_name:, event_params: {})
        return false unless enabled?

        measurement_id = credentials['measurement_id']
        api_secret = credentials['api_secret']

        return false unless measurement_id && api_secret

        with_logging('ga_event', metadata: { event_name: event_name, client_id: client_id }) do
          uri = URI("https://www.google-analytics.com/mp/collect?measurement_id=#{measurement_id}&api_secret=#{api_secret}")

          payload = {
            client_id: client_id,
            events: [
              {
                name: event_name,
                params: event_params
              }
            ]
          }

          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true
          request = Net::HTTP::Post.new(uri.path)
          request['Content-Type'] = 'application/json'
          request.body = payload.to_json

          response = http.request(request)
          response.is_a?(Net::HTTPSuccess)
        end
      end

      # Generate tracking script for views
      def tracking_script
        return '' unless enabled?

        measurement_id = credentials['measurement_id']
        return '' unless measurement_id

        <<~JAVASCRIPT
          <!-- Google Analytics 4 -->
          <script async src="https://www.googletagmanager.com/gtag/js?id=#{measurement_id}"></script>
          <script>
            window.dataLayer = window.dataLayer || [];
            function gtag(){dataLayer.push(arguments);}
            gtag('js', new Date());
            gtag('config', '#{measurement_id}');
          </script>
        JAVASCRIPT
      end

      private

      def integration_type_key
        'google_analytics'
      end

      def rails_credentials_fallback
        ga_config = Rails.application.credentials.dig(:google_analytics) || {}
        {
          measurement_id: ga_config[:measurement_id],
          api_secret: ga_config[:api_secret]
        }.compact
      end

      def missing_credentials_error
        {
          success: false,
          message: 'Отсутствует обязательный параметр: measurement_id'
        }
      end
    end
  end
end
