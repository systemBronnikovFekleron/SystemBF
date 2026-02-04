# frozen_string_literal: true

class TelegramBotService
  API_URL = 'https://api.telegram.org'

  class << self
    def send_message(chat_id, text, options = {})
      token = Rails.application.credentials.dig(:telegram, :bot_token)
      return false unless token

      uri = URI("#{API_URL}/bot#{token}/sendMessage")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      params = {
        chat_id: chat_id,
        text: text,
        parse_mode: options[:parse_mode] || 'HTML'
      }

      # Add inline keyboard if provided
      params[:reply_markup] = options[:reply_markup].to_json if options[:reply_markup]

      request = Net::HTTP::Post.new(uri.path, 'Content-Type' => 'application/json')
      request.body = params.to_json

      response = http.request(request)
      JSON.parse(response.body)
    rescue StandardError => e
      Rails.logger.error "Telegram API Error: #{e.message}"
      false
    end

    def set_webhook(url)
      token = Rails.application.credentials.dig(:telegram, :bot_token)
      return false unless token

      uri = URI("#{API_URL}/bot#{token}/setWebhook")
      response = Net::HTTP.post_form(uri, url: url)

      result = JSON.parse(response.body)
      result['ok']
    rescue StandardError => e
      Rails.logger.error "Telegram Webhook Setup Error: #{e.message}"
      false
    end

    def delete_webhook
      token = Rails.application.credentials.dig(:telegram, :bot_token)
      return false unless token

      uri = URI("#{API_URL}/bot#{token}/deleteWebhook")
      response = Net::HTTP.get(uri)

      result = JSON.parse(response)
      result['ok']
    rescue StandardError => e
      Rails.logger.error "Telegram Webhook Delete Error: #{e.message}"
      false
    end

    def format_currency(kopecks)
      Money.new(kopecks, 'RUB').format
    end

    def format_date(date)
      date&.strftime('%d.%m.%Y')
    end
  end
end
