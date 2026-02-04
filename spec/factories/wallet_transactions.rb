# frozen_string_literal: true

FactoryBot.define do
  factory :wallet_transaction do
    association :wallet
    transaction_type { 'deposit' }
    amount_kopecks { 100_000 }
    balance_before_kopecks { 50_000 }
    balance_after_kopecks { 150_000 }
    description { 'Тестовая транзакция' }

    trait :deposit do
      transaction_type { 'deposit' }
      amount_kopecks { 100_000 }
      description { 'Пополнение кошелька' }
    end

    trait :withdrawal do
      transaction_type { 'withdrawal' }
      amount_kopecks { -50_000 }
      description { 'Списание средств' }
      association :order_request
    end

    trait :refund do
      transaction_type { 'refund' }
      amount_kopecks { 50_000 }
      description { 'Возврат средств' }
      association :order_request
    end

    trait :with_external_id do
      external_id { "CP-#{SecureRandom.hex(8)}" }
    end
  end
end
