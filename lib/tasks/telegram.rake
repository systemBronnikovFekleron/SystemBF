# frozen_string_literal: true

namespace :telegram do
  desc 'Setup Telegram bot webhook'
  task setup_webhook: :environment do
    token = Rails.application.credentials.dig(:telegram, :bot_token)

    unless token
      puts '❌ Telegram bot token not found in credentials.'
      puts 'Run: EDITOR="nano" rails credentials:edit'
      puts 'Add: telegram:\n  bot_token: YOUR_BOT_TOKEN'
      exit 1
    end

    app_url = ENV.fetch('APP_URL', nil)

    unless app_url
      puts '❌ APP_URL environment variable not set.'
      puts 'Set APP_URL to your production domain (e.g., https://platform.bronnikov.com)'
      exit 1
    end

    webhook_url = "#{app_url}/webhooks/telegram/#{token}"

    puts "🤖 Setting up Telegram webhook..."
    puts "Webhook URL: #{webhook_url}"

    if TelegramBotService.set_webhook(webhook_url)
      puts "✅ Webhook set successfully!"
      puts ""
      puts "Test your bot:"
      puts "1. Open Telegram"
      puts "2. Find your bot (search by @your_bot_name)"
      puts "3. Send /start command"
    else
      puts "❌ Failed to set webhook. Check your bot token and URL."
      exit 1
    end
  end

  desc 'Delete Telegram bot webhook'
  task delete_webhook: :environment do
    puts "🤖 Deleting Telegram webhook..."

    if TelegramBotService.delete_webhook
      puts "✅ Webhook deleted successfully!"
    else
      puts "❌ Failed to delete webhook."
      exit 1
    end
  end

  desc 'Test Telegram bot connection'
  task test: :environment do
    token = Rails.application.credentials.dig(:telegram, :bot_token)

    unless token
      puts '❌ Telegram bot token not found.'
      exit 1
    end

    uri = URI("https://api.telegram.org/bot#{token}/getMe")
    response = Net::HTTP.get(uri)
    result = JSON.parse(response)

    if result['ok']
      bot_info = result['result']
      puts "✅ Bot connected successfully!"
      puts ""
      puts "Bot info:"
      puts "  Username: @#{bot_info['username']}"
      puts "  First name: #{bot_info['first_name']}"
      puts "  ID: #{bot_info['id']}"
    else
      puts "❌ Bot connection failed. Check your token."
      exit 1
    end
  rescue StandardError => e
    puts "❌ Error: #{e.message}"
    exit 1
  end
end
