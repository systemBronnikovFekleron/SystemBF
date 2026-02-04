# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'base64'

module IntegrationServices
  class CloudPaymentsService < BaseService
    class << self
      def test_connection(credentials, settings = {})
        public_id = credentials['public_id'] || credentials[:public_id]
        api_secret = credentials['api_secret'] || credentials[:api_secret]

        return missing_credentials_error unless public_id && api_secret

        begin
          # Тестовый запрос к CloudPayments API - проверяем тестовую транзакцию
          uri = URI('https://api.cloudpayments.ru/test')
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true

          request = Net::HTTP::Post.new(uri.path)
          request['Content-Type'] = 'application/json'
          request['Authorization'] = 'Basic ' + Base64.strict_encode64("#{public_id}:#{api_secret}")
          request.body = { RequestId: SecureRandom.uuid }.to_json

          response = http.request(request)

          if response.is_a?(Net::HTTPSuccess)
            data = JSON.parse(response.body)
            if data['Success']
              {
                success: true,
                message: "CloudPayments подключен (Public ID: #{public_id})"
              }
            else
              {
                success: false,
                message: "CloudPayments API вернул ошибку: #{data['Message']}"
              }
            end
          elsif response.code == '401'
            {
              success: false,
              message: 'Ошибка аутентификации: неверный Public ID или API Secret'
            }
          else
            {
              success: false,
              message: "HTTP ошибка: #{response.code} #{response.message}"
            }
          end
        rescue JSON::ParserError => e
          {
            success: false,
            message: "Ошибка парсинга ответа: #{e.message}"
          }
        rescue StandardError => e
          {
            success: false,
            message: "Ошибка подключения к CloudPayments: #{e.message}"
          }
        end
      end

      # Verify webhook signature
      def verify_webhook_signature(request_body, signature)
        return false unless enabled?

        api_secret = credentials['api_secret']
        return false unless api_secret

        expected_signature = Base64.strict_encode64(
          OpenSSL::HMAC.digest('SHA256', api_secret, request_body)
        )

        expected_signature == signature
      end

      # Create payment widget configuration
      def widget_config(amount_kopecks:, currency: 'RUB', description:, invoice_id: nil, **options)
        return nil unless enabled?

        public_id = credentials['public_id']
        return nil unless public_id

        {
          publicId: public_id,
          description: description,
          amount: (amount_kopecks / 100.0).round(2),
          currency: currency,
          invoiceId: invoice_id || SecureRandom.uuid,
          skin: settings['widget_skin'] || 'modern',
          language: settings['widget_language'] || 'ru-RU'
        }.merge(options)
      end

      private

      def integration_type_key
        'cloudpayments'
      end

      def rails_credentials_fallback
        cp_config = Rails.application.credentials.dig(:cloudpayments) || {}
        {
          public_id: cp_config[:public_id],
          api_secret: cp_config[:api_secret]
        }.compact
      end

      def missing_credentials_error
        {
          success: false,
          message: 'Отсутствуют обязательные параметры: public_id, api_secret'
        }
      end
    end
  end
end
