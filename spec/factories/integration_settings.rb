# frozen_string_literal: true

FactoryBot.define do
  factory :integration_setting do
    integration_type { 'email' }
    sequence(:name) { |n| "Integration #{n}" }
    description { 'Integration description' }
    enabled { false }
    settings { {} }

    trait :email do
      integration_type { 'email' }
      name { 'Email Integration' }
      description { 'SMTP email integration' }
      encrypted_credentials do
        {
          smtp_address: 'smtp.example.com',
          smtp_port: '587',
          smtp_domain: 'example.com',
          smtp_user_name: 'user@example.com',
          smtp_password: 'password123',
          smtp_authentication: 'plain',
          smtp_enable_starttls_auto: 'true'
        }.to_json
      end
      settings do
        {
          from_email: 'noreply@example.com',
          from_name: 'Система Бронникова'
        }
      end
    end

    trait :telegram do
      integration_type { 'telegram' }
      name { 'Telegram Bot' }
      description { 'Telegram bot integration' }
      encrypted_credentials do
        {
          bot_token: '1234567890:ABCdefGHIjklMNOpqrsTUVwxyz',
          webhook_url: 'https://example.com/webhooks/telegram'
        }.to_json
      end
      settings do
        {
          welcome_message: 'Добро пожаловать!',
          commands_enabled: true
        }
      end
    end

    trait :google_analytics do
      integration_type { 'google_analytics' }
      name { 'Google Analytics' }
      description { 'Google Analytics 4 integration' }
      encrypted_credentials do
        {
          measurement_id: 'G-XXXXXXXXXX',
          api_secret: 'api_secret_key'
        }.to_json
      end
      settings do
        {
          track_page_views: true,
          track_events: true
        }
      end
    end

    trait :cloudpayments do
      integration_type { 'cloudpayments' }
      name { 'CloudPayments' }
      description { 'CloudPayments payment gateway' }
      encrypted_credentials do
        {
          public_id: 'pk_test_1234567890',
          api_secret: 'api_secret_key'
        }.to_json
      end
      settings do
        {
          currency: 'RUB',
          test_mode: true
        }
      end
    end

    trait :enabled do
      enabled { true }
    end

    trait :disabled do
      enabled { false }
    end

    trait :healthy do
      last_test_at { 1.hour.ago }
      last_test_status { 'success' }
      last_test_message { 'Подключение успешно' }
    end

    trait :unhealthy do
      last_test_at { 1.hour.ago }
      last_test_status { 'failed' }
      last_test_message { 'Ошибка подключения' }
    end

    trait :with_usage do
      usage_count { 100 }
      last_used_at { 1.hour.ago }
    end
  end
end
