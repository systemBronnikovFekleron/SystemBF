# frozen_string_literal: true

FactoryBot.define do
  factory :initiation do
    association :user
    association :conducted_by, factory: :user
    initiation_type { 'first' }
    level { 1 }
    conducted_at { 1.week.ago }
    status { :completed }
    notes { 'Успешно пройдена инициация первого уровня' }
    results { { score: 85, comments: 'Хороший результат' } }

    trait :pending do
      status { :pending }
      conducted_at { nil }
    end

    trait :passed do
      status { :passed }
    end

    trait :failed do
      status { :failed }
    end
  end
end
