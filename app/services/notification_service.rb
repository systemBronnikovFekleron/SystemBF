# frozen_string_literal: true

# NotificationService - создание уведомлений для пользователей
class NotificationService
  class << self
    # Базовый метод создания уведомления
    def notify(user, type, title, message, action_url: nil, action_text: nil, metadata: {})
      Notification.create!(
        user: user,
        notification_type: type,
        title: title,
        message: message,
        action_url: action_url,
        action_text: action_text,
        metadata: metadata
      )
    end

    # === Order-related notifications ===

    def order_paid(user, order)
      notify(
        user,
        'order_paid',
        'Заказ оплачен',
        "Ваш заказ №#{order.order_number} успешно оплачен на сумму #{humanize_money(order.total_kopecks)}. Доступ к материалам открыт.",
        action_url: '/dashboard/orders',
        action_text: 'Смотреть заказ',
        metadata: { order_id: order.id, order_number: order.order_number }
      )
    end

    def order_completed(user, order)
      notify(
        user,
        'order_completed',
        'Заказ завершен',
        "Ваш заказ №#{order.order_number} успешно завершен. Спасибо за покупку!",
        action_url: '/dashboard/orders',
        action_text: 'Смотреть заказ',
        metadata: { order_id: order.id, order_number: order.order_number }
      )
    end

    # === Product Access ===

    def product_access_granted(user, product)
      notify(
        user,
        'product_access_granted',
        'Доступ открыт',
        "Вам открыт доступ к курсу \"#{product.name}\". Начните обучение прямо сейчас!",
        action_url: '/dashboard/my-courses',
        action_text: 'Начать обучение',
        metadata: { product_id: product.id, product_name: product.name }
      )
    end

    # === Wallet notifications ===

    def wallet_deposit(user, amount_kopecks, source: nil)
      notify(
        user,
        'wallet_deposit',
        'Пополнение кошелька',
        "На ваш кошелек зачислено #{humanize_money(amount_kopecks)}. Текущий баланс: #{humanize_money(user.wallet.balance_kopecks)}.",
        action_url: '/dashboard/wallet',
        action_text: 'Смотреть кошелек',
        metadata: { amount_kopecks: amount_kopecks, source: source }
      )
    end

    def wallet_withdrawal(user, amount_kopecks, target: nil)
      notify(
        user,
        'wallet_withdrawal',
        'Списание с кошелька',
        "С вашего кошелька списано #{humanize_money(amount_kopecks)}. Текущий баланс: #{humanize_money(user.wallet.balance_kopecks)}.",
        action_url: '/dashboard/wallet',
        action_text: 'Смотреть кошелек',
        metadata: { amount_kopecks: amount_kopecks, target: target }
      )
    end

    def wallet_refund(user, amount_kopecks, reason: nil)
      notify(
        user,
        'wallet_refund',
        'Возврат средств',
        "На ваш кошелек возвращено #{humanize_money(amount_kopecks)}. Причина: #{reason || 'Возврат платежа'}.",
        action_url: '/dashboard/wallet',
        action_text: 'Смотреть кошелек',
        metadata: { amount_kopecks: amount_kopecks, reason: reason }
      )
    end

    # === OrderRequest notifications ===

    def order_request_created(user, order_request)
      notify(
        user,
        'order_request_created',
        'Заявка создана',
        "Ваша заявка №#{order_request.request_number} на \"#{order_request.product.name}\" создана и ожидает одобрения.",
        action_url: '/dashboard/orders',
        action_text: 'Смотреть заявку',
        metadata: { order_request_id: order_request.id, request_number: order_request.request_number }
      )
    end

    def order_request_approved(user, order_request)
      notify(
        user,
        'order_request_approved',
        'Заявка одобрена',
        "Ваша заявка №#{order_request.request_number} одобрена. Вы можете оплатить заказ.",
        action_url: '/dashboard/orders',
        action_text: 'Оплатить',
        metadata: { order_request_id: order_request.id, request_number: order_request.request_number }
      )
    end

    def order_request_rejected(user, order_request, reason: nil)
      notify(
        user,
        'order_request_rejected',
        'Заявка отклонена',
        "Ваша заявка №#{order_request.request_number} отклонена. Причина: #{reason || 'Не указана'}.",
        action_url: '/dashboard/orders',
        action_text: 'Смотреть заявку',
        metadata: { order_request_id: order_request.id, request_number: order_request.request_number, reason: reason }
      )
    end

    def order_request_paid(user, order_request)
      notify(
        user,
        'order_request_paid',
        'Заявка оплачена',
        "Ваша заявка №#{order_request.request_number} успешно оплачена. Доступ к материалам открыт.",
        action_url: '/dashboard/my-courses',
        action_text: 'Начать обучение',
        metadata: { order_request_id: order_request.id, request_number: order_request.request_number }
      )
    end

    # === Event notifications ===

    def event_registration(user, event)
      notify(
        user,
        'event_registration',
        'Регистрация на событие',
        "Вы зарегистрированы на событие \"#{event.title}\", которое состоится #{format_date(event.starts_at)}.",
        action_url: '/dashboard/events',
        action_text: 'Мои события',
        metadata: { event_id: event.id, event_title: event.title }
      )
    end

    def event_reminder(user, event)
      notify(
        user,
        'event_reminder',
        'Напоминание о событии',
        "Напоминаем, что событие \"#{event.title}\" начнется через 24 часа - #{format_datetime(event.starts_at)}.",
        action_url: "/events/#{event.slug}",
        action_text: 'Подробнее',
        metadata: { event_id: event.id, event_title: event.title }
      )
    end

    # === Development notifications ===

    def initiation_completed(user, initiation)
      notify(
        user,
        'initiation_completed',
        'Инициация завершена',
        "Ваша инициация \"#{initiation.initiation_type_label}\" завершена. Результаты доступны в карте развития.",
        action_url: '/dashboard/development-map',
        action_text: 'Смотреть результаты',
        metadata: { initiation_id: initiation.id, initiation_type: initiation.initiation_type }
      )
    end

    def diagnostic_completed(user, diagnostic)
      notify(
        user,
        'diagnostic_completed',
        'Диагностика завершена',
        "Ваша диагностика \"#{diagnostic.diagnostic_type_label}\" завершена. Результаты и рекомендации доступны.",
        action_url: '/dashboard/development-map',
        action_text: 'Смотреть результаты',
        metadata: { diagnostic_id: diagnostic.id, diagnostic_type: diagnostic.diagnostic_type }
      )
    end

    # === Achievement ===

    def achievement_unlocked(user, achievement_name, description)
      notify(
        user,
        'achievement_unlocked',
        'Достижение разблокировано!',
        "Вы получили достижение \"#{achievement_name}\": #{description}",
        action_url: '/dashboard/achievements',
        action_text: 'Мои достижения',
        metadata: { achievement_name: achievement_name }
      )
    end

    # === System ===

    def system_notification(user, title, message, action_url: nil, action_text: nil)
      notify(
        user,
        'system',
        title,
        message,
        action_url: action_url,
        action_text: action_text
      )
    end

    # Broadcast notification to all users (для admin)
    def broadcast_to_all(title, message, action_url: nil, action_text: nil)
      User.find_each do |user|
        system_notification(user, title, message, action_url: action_url, action_text: action_text)
      end
    end

    private

    # Форматирование денег
    def humanize_money(kopecks)
      Money.new(kopecks, 'RUB').format
    end

    # Форматирование даты
    def format_date(date)
      I18n.l(date, format: :long)
    end

    # Форматирование даты и времени
    def format_datetime(datetime)
      I18n.l(datetime, format: :long)
    end
  end
end
