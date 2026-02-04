# frozen_string_literal: true

require 'net/http'
require 'uri'

module IntegrationServices
  class TelegramService < BaseService
    class << self
      def test_connection(credentials, settings = {})
        bot_token = credentials['bot_token'] || credentials[:bot_token]

        return missing_credentials_error unless bot_token

        begin
          uri = URI("https://api.telegram.org/bot#{bot_token}/getMe")
          response = Net::HTTP.get_response(uri)

          if response.is_a?(Net::HTTPSuccess)
            data = JSON.parse(response.body)
            if data['ok']
              bot_info = data['result']
              {
                success: true,
                message: "Telegram бот подключен: @#{bot_info['username']} (#{bot_info['first_name']})"
              }
            else
              {
                success: false,
                message: "Ошибка Telegram API: #{data['description']}"
              }
            end
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
            message: "Ошибка подключения к Telegram: #{e.message}"
          }
        end
      end

      # Send message via Telegram
      def send_message(chat_id:, text:, parse_mode: 'HTML', reply_markup: nil)
        return false unless enabled?

        bot_token = credentials['bot_token']
        return false unless bot_token

        with_logging('telegram_message', metadata: { chat_id: chat_id }) do
          uri = URI("https://api.telegram.org/bot#{bot_token}/sendMessage")
          params = {
            chat_id: chat_id,
            text: text,
            parse_mode: parse_mode
          }
          params[:reply_markup] = reply_markup.to_json if reply_markup

          response = Net::HTTP.post_form(uri, params)
          data = JSON.parse(response.body)

          data['ok']
        end
      end

      # Set webhook
      def set_webhook(webhook_url)
        return false unless enabled?

        bot_token = credentials['bot_token']
        return false unless bot_token

        with_logging('telegram_webhook_set', metadata: { url: webhook_url }) do
          uri = URI("https://api.telegram.org/bot#{bot_token}/setWebhook")
          response = Net::HTTP.post_form(uri, { url: webhook_url })
          data = JSON.parse(response.body)

          data['ok']
        end
      end

      private

      def integration_type_key
        'telegram'
      end

      def rails_credentials_fallback
        telegram_config = Rails.application.credentials.dig(:telegram) || {}
        {
          bot_token: telegram_config[:bot_token],
          webhook_url: telegram_config[:webhook_url]
        }.compact
      end

      def missing_credentials_error
        {
          success: false,
          message: 'Отсутствует обязательный параметр: bot_token'
        }
      end
    end
  end
end
