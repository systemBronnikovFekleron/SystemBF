# frozen_string_literal: true

FactoryBot.define do
  factory :notification do
    association :user
    notification_type { 'system' }
    title { 'Test Notification' }
    message { 'This is a test notification message' }
    read { false }
    action_url { nil }
    action_text { nil }
    metadata { {} }

    trait :unread do
      read { false }
    end

    trait :read do
      read { true }
    end

    trait :order_paid do
      notification_type { 'order_paid' }
      title { 'Заказ оплачен' }
      message { 'Ваш заказ успешно оплачен' }
    end

    trait :product_access do
      notification_type { 'product_access_granted' }
      title { 'Доступ открыт' }
      message { 'Вам открыт доступ к курсу' }
    end

    trait :with_action do
      action_url { '/dashboard/orders' }
      action_text { 'Смотреть заказ' }
    end
  end
end
