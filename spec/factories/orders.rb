# frozen_string_literal: true

FactoryBot.define do
  factory :order do
    association :user
    total_kopecks { 100000 } # 1000 руб
    status { :pending }
    payment_method { 'wallet' }

    trait :paid do
      status { :paid }
      paid_at { Time.current }
    end

    trait :completed do
      status { :completed }
      paid_at { 1.day.ago }
    end

    trait :failed do
      status { :failed }
    end

    trait :refunded do
      status { :refunded }
    end
  end
end
