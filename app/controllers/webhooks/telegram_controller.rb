# frozen_string_literal: true

module Webhooks
  class TelegramController < ApplicationController
    skip_before_action :verify_authenticity_token

    def webhook
      message = params[:message]

      return head :ok unless message

      chat_id = message[:chat][:id]
      text = message[:text]
      from_user = message[:from]

      # Handle commands
      case text
      when '/start'
        handle_start(chat_id, from_user)
      when '/balance'
        handle_balance(chat_id)
      when '/orders'
        handle_orders(chat_id)
      when '/courses'
        handle_courses(chat_id)
      when '/help'
        handle_help(chat_id)
      when '/link'
        handle_link(chat_id, from_user)
      else
        handle_unknown(chat_id)
      end

      head :ok
    end

    private

    def handle_start(chat_id, from_user)
      username = from_user[:username] || from_user[:first_name]

      text = <<~TEXT
        👋 Добро пожаловать в <b>Систему Бронникова</b>!

        Я бот-помощник платформы.

        <b>Доступные команды:</b>
        /link - Привязать Telegram к аккаунту
        /balance - Баланс кошелька
        /orders - Последние заказы
        /courses - Мои курсы
        /help - Помощь

        Для начала работы используйте команду /link для привязки вашего Telegram аккаунта.
      TEXT

      TelegramBotService.send_message(chat_id, text)
    end

    def handle_link(chat_id, from_user)
      # Generate unique link token
      token = SecureRandom.urlsafe_base64(32)

      # Store token in cache with chat_id (expires in 10 minutes)
      Rails.cache.write("telegram_link_#{token}", {
        chat_id: chat_id,
        username: from_user[:username],
        first_name: from_user[:first_name]
      }, expires_in: 10.minutes)

      link_url = "#{ENV.fetch('APP_URL', 'https://platform.bronnikov.com')}/telegram/link/#{token}"

      text = <<~TEXT
        🔗 <b>Привязка Telegram аккаунта</b>

        Перейдите по ссылке для привязки:
        #{link_url}

        ⏰ Ссылка действительна 10 минут.

        После привязки вы сможете:
        • Проверять баланс кошелька
        • Просматривать заказы
        • Получать уведомления о курсах
      TEXT

      TelegramBotService.send_message(chat_id, text)
    end

    def handle_balance(chat_id)
      user = find_user_by_telegram(chat_id)

      unless user
        send_not_linked_message(chat_id)
        return
      end

      balance = user.wallet.balance_kopecks
      formatted_balance = TelegramBotService.format_currency(balance)

      text = <<~TEXT
        💰 <b>Баланс кошелька</b>

        Текущий баланс: <b>#{formatted_balance}</b>

        Для пополнения перейдите в личный кабинет:
        #{ENV.fetch('APP_URL', 'https://platform.bronnikov.com')}/dashboard/wallet
      TEXT

      TelegramBotService.send_message(chat_id, text)
    end

    def handle_orders(chat_id)
      user = find_user_by_telegram(chat_id)

      unless user
        send_not_linked_message(chat_id)
        return
      end

      orders = user.orders.order(created_at: :desc).limit(5)

      if orders.empty?
        text = "📦 У вас пока нет заказов."
        TelegramBotService.send_message(chat_id, text)
        return
      end

      text = "📦 <b>Последние заказы:</b>\n\n"

      orders.each do |order|
        status_emoji = order_status_emoji(order.status)
        formatted_total = TelegramBotService.format_currency(order.total_kopecks)
        formatted_date = TelegramBotService.format_date(order.created_at)

        text += "#{status_emoji} <b>#{order.order_number}</b>\n"
        text += "Сумма: #{formatted_total}\n"
        text += "Статус: #{order_status_text(order.status)}\n"
        text += "Дата: #{formatted_date}\n\n"
      end

      text += "\nПодробнее в личном кабинете:\n"
      text += "#{ENV.fetch('APP_URL', 'https://platform.bronnikov.com')}/dashboard/orders"

      TelegramBotService.send_message(chat_id, text)
    end

    def handle_courses(chat_id)
      user = find_user_by_telegram(chat_id)

      unless user
        send_not_linked_message(chat_id)
        return
      end

      courses = user.product_accesses.includes(:product).limit(10)

      if courses.empty?
        text = <<~TEXT
          🎓 У вас пока нет активных курсов.

          Посмотрите доступные курсы:
          #{ENV.fetch('APP_URL', 'https://platform.bronnikov.com')}/products?product_type=course
        TEXT
        TelegramBotService.send_message(chat_id, text)
        return
      end

      text = "🎓 <b>Мои курсы:</b>\n\n"

      courses.each do |access|
        product = access.product
        product_icon = product_type_icon(product.product_type)

        text += "#{product_icon} <b>#{product.name}</b>\n"
        text += "Тип: #{product_type_label(product.product_type)}\n"
        text += "Доступ с: #{TelegramBotService.format_date(access.created_at)}\n\n"
      end

      text += "\nВсе курсы в личном кабинете:\n"
      text += "#{ENV.fetch('APP_URL', 'https://platform.bronnikov.com')}/dashboard/my-courses"

      TelegramBotService.send_message(chat_id, text)
    end

    def handle_help(chat_id)
      text = <<~TEXT
        ℹ️ <b>Помощь</b>

        <b>Доступные команды:</b>

        /start - Начать работу
        /link - Привязать Telegram к аккаунту
        /balance - Проверить баланс кошелька
        /orders - Последние заказы
        /courses - Мои курсы
        /help - Показать эту справку

        <b>Поддержка:</b>
        Email: support@bronnikov.com
        Сайт: https://bronnikov.com

        <b>Личный кабинет:</b>
        #{ENV.fetch('APP_URL', 'https://platform.bronnikov.com')}/dashboard
      TEXT

      TelegramBotService.send_message(chat_id, text)
    end

    def handle_unknown(chat_id)
      text = <<~TEXT
        ❓ Команда не распознана.

        Используйте /help для просмотра доступных команд.
      TEXT

      TelegramBotService.send_message(chat_id, text)
    end

    def send_not_linked_message(chat_id)
      text = <<~TEXT
        🔗 <b>Telegram не привязан к аккаунту</b>

        Для использования этой команды необходимо привязать ваш Telegram к аккаунту платформы.

        Используйте команду /link для получения ссылки.
      TEXT

      TelegramBotService.send_message(chat_id, text)
    end

    def find_user_by_telegram(chat_id)
      User.find_by(telegram_chat_id: chat_id)
    end

    def order_status_emoji(status)
      case status
      when 'paid', 'completed'
        '✅'
      when 'pending'
        '⏳'
      when 'failed', 'cancelled'
        '❌'
      when 'refunded'
        '↩️'
      else
        '📦'
      end
    end

    def order_status_text(status)
      I18n.t("order.status.#{status}", default: status.humanize)
    end

    def product_type_icon(type)
      case type
      when 'video_course', 'course'
        '🎓'
      when 'book'
        '📚'
      when 'service'
        '⚙️'
      when 'event_access'
        '🎫'
      else
        '📦'
      end
    end

    def product_type_label(type)
      I18n.t("product.type.#{type}", default: type.humanize)
    end
  end
end
