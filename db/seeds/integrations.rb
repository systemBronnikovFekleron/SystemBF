# frozen_string_literal: true

puts "Создание настроек интеграций..."

# Email Integration
email_integration = IntegrationSetting.find_or_create_by!(integration_type: 'email') do |integration|
  integration.name = 'Email (SMTP)'
  integration.description = 'Отправка email уведомлений через SMTP'
  integration.enabled = false
  integration.settings = {
    'from_email' => 'noreply@bronnikov.com',
    'from_name' => 'Система Бронникова',
    'reply_to_email' => 'support@bronnikov.com'
  }
  integration.usage_count = rand(100..500)
  integration.last_used_at = rand(1..48).hours.ago
end

puts "✓ Email интеграция создана (#{email_integration.id})"

# Telegram Integration
telegram_integration = IntegrationSetting.find_or_create_by!(integration_type: 'telegram') do |integration|
  integration.name = 'Telegram Bot'
  integration.description = 'Уведомления и взаимодействие через Telegram бота'
  integration.enabled = false
  integration.settings = {
    'welcome_message' => 'Добро пожаловать в бот Системы Бронникова!',
    'commands_enabled' => true
  }
  integration.usage_count = rand(50..300)
  integration.last_used_at = rand(1..24).hours.ago
end

puts "✓ Telegram интеграция создана (#{telegram_integration.id})"

# Google Analytics Integration
ga_integration = IntegrationSetting.find_or_create_by!(integration_type: 'google_analytics') do |integration|
  integration.name = 'Google Analytics'
  integration.description = 'Аналитика посещений и поведения пользователей'
  integration.enabled = false
  integration.settings = {
    'track_page_views' => true,
    'track_events' => true
  }
  integration.usage_count = rand(1000..5000)
  integration.last_used_at = rand(1..6).hours.ago
end

puts "✓ Google Analytics интеграция создана (#{ga_integration.id})"

# CloudPayments Integration
cp_integration = IntegrationSetting.find_or_create_by!(integration_type: 'cloudpayments') do |integration|
  integration.name = 'CloudPayments'
  integration.description = 'Прием платежей через CloudPayments'
  integration.enabled = false
  integration.settings = {
    'currency' => 'RUB',
    'widget_skin' => 'modern',
    'widget_language' => 'ru-RU',
    'test_mode' => true
  }
  integration.usage_count = rand(200..800)
  integration.last_used_at = rand(1..12).hours.ago
end

puts "✓ CloudPayments интеграция создана (#{cp_integration.id})"

# Создание тестовых логов для каждой интеграции
puts "\nСоздание тестовых логов..."

[email_integration, telegram_integration, ga_integration, cp_integration].each do |integration|
  # Логи за последние 7 дней
  7.times do |day_offset|
    date = day_offset.days.ago

    # Успешные события
    rand(10..30).times do
      IntegrationLog.create!(
        integration_setting: integration,
        event_type: %w[api_call webhook email_sent test_connection].sample,
        status: 'success',
        message: 'Операция выполнена успешно',
        metadata: { test: true, day: day_offset },
        duration_ms: rand(50..500),
        created_at: date + rand(0..23).hours + rand(0..59).minutes
      )
    end

    # Несколько ошибок
    rand(0..5).times do
      IntegrationLog.create!(
        integration_setting: integration,
        event_type: %w[api_call webhook].sample,
        status: 'failed',
        message: 'Ошибка выполнения операции',
        error_details: "Connection timeout\nat /app/services/integration_service.rb:42",
        metadata: { test: true, day: day_offset },
        duration_ms: rand(1000..5000),
        created_at: date + rand(0..23).hours + rand(0..59).minutes
      )
    end
  end

  puts "  ✓ Создано #{integration.integration_logs.count} логов для #{integration.name}"
end

# Создание статистики
puts "\nСоздание статистики..."

[email_integration, telegram_integration, ga_integration, cp_integration].each do |integration|
  30.times do |day_offset|
    date = day_offset.days.ago.to_date

    total = rand(20..100)
    successful = (total * rand(0.85..0.99)).to_i
    failed = total - successful

    IntegrationStatistic.find_or_create_by!(
      integration_setting: integration,
      date: date,
      period_type: 'daily'
    ) do |stat|
      stat.total_requests = total
      stat.successful_requests = successful
      stat.failed_requests = failed
      stat.avg_duration_ms = rand(100..800)
    end
  end

  puts "  ✓ Создано 30 дней статистики для #{integration.name}"
end

puts "\n✅ Настройки интеграций созданы успешно!"
