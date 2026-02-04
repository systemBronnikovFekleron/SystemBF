# frozen_string_literal: true

FactoryBot.define do
  factory :integration_log do
    association :integration_setting
    event_type { 'api_call' }
    status { 'success' }
    message { 'Операция выполнена успешно' }
    metadata { {} }
    duration_ms { 150 }

    trait :api_call do
      event_type { 'api_call' }
      message { 'API запрос выполнен' }
      metadata { { endpoint: '/api/v1/test', method: 'GET' } }
    end

    trait :webhook do
      event_type { 'webhook' }
      message { 'Webhook получен' }
      metadata { { source: 'external_service', payload_size: 1024 } }
    end

    trait :email_sent do
      event_type { 'email_sent' }
      message { 'Email отправлен' }
      metadata { { to: 'test@example.com', subject: 'Test email' } }
    end

    trait :test_connection do
      event_type { 'test_connection' }
      message { 'Тест подключения выполнен' }
    end

    trait :success do
      status { 'success' }
      message { 'Операция выполнена успешно' }
    end

    trait :failed do
      status { 'failed' }
      message { 'Ошибка выполнения операции' }
      error_details { 'Connection timeout after 30 seconds' }
    end

    trait :pending do
      status { 'pending' }
      message { 'Операция в процессе' }
    end

    trait :with_error do
      status { 'failed' }
      error_details do
        <<~ERROR
          StandardError: Connection failed
          at /app/services/integration_service.rb:42
          at /app/controllers/webhooks_controller.rb:15
        ERROR
      end
    end

    trait :with_related do
      association :related, factory: :order
    end

    trait :slow do
      duration_ms { 5000 }
    end

    trait :fast do
      duration_ms { 50 }
    end
  end
end
