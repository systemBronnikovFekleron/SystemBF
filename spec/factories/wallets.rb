# frozen_string_literal: true

FactoryBot.define do
  factory :wallet do
    association :user
    balance_kopecks { 100_000 } # Default 1000 RUB

    trait :empty do
      balance_kopecks { 0 }
    end

    trait :wealthy do
      balance_kopecks { 1_000_000 } # 10,000 RUB
    end

    trait :with_transactions do
      after(:create) do |wallet|
        create_list(:wallet_transaction, 3, wallet: wallet)
      end
    end
  end
end
