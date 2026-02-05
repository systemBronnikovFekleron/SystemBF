# frozen_string_literal: true

FactoryBot.define do
  factory :diagnostic do
    association :user
    association :conducted_by, factory: :user
    diagnostic_type { 'vision' }
    conducted_at { 3.days.ago }
    status { :completed }
    results { { vision_score: 80, bioenergy_score: 75 } }
    recommendations { 'Продолжайте развивать навыки визуализации' }
    score { 77 }

    trait :scheduled do
      status { :scheduled }
      conducted_at { 3.days.from_now }
    end

    trait :cancelled do
      status { :cancelled }
    end

    trait :bioenergy do
      diagnostic_type { 'bioenergy' }
    end

    trait :psychobiocomputer do
      diagnostic_type { 'psychobiocomputer' }
    end
  end
end
