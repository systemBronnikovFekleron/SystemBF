# frozen_string_literal: true

class TelegramController < ApplicationController
  before_action :authenticate_user!

  def link
    token = params[:token]
    telegram_data = Rails.cache.read("telegram_link_#{token}")

    unless telegram_data
      redirect_to dashboard_path, alert: 'Ссылка недействительна или истекла. Используйте /link в боте заново.'
      return
    end

    # Link user's Telegram
    if current_user.update(telegram_chat_id: telegram_data[:chat_id])
      # Delete token from cache
      Rails.cache.delete("telegram_link_#{token}")

      # Send confirmation message to Telegram
      TelegramBotService.send_message(
        telegram_data[:chat_id],
        "✅ <b>Telegram успешно привязан!</b>\n\n" \
        "Теперь вы можете использовать команды:\n" \
        "/balance - Баланс кошелька\n" \
        "/orders - Последние заказы\n" \
        "/courses - Мои курсы"
      )

      redirect_to dashboard_path, notice: 'Telegram успешно привязан к вашему аккаунту!'
    else
      redirect_to dashboard_path, alert: 'Ошибка при привязке Telegram. Попробуйте снова.'
    end
  end
end
