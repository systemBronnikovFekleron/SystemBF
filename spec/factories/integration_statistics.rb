# frozen_string_literal: true

FactoryBot.define do
  factory :integration_statistic do
    association :integration_setting
    date { Date.current }
    period_type { 'daily' }
    total_requests { 100 }
    successful_requests { 95 }
    failed_requests { 5 }
    avg_duration_ms { 250 }

    trait :daily do
      period_type { 'daily' }
      date { Date.current }
    end

    trait :weekly do
      period_type { 'weekly' }
      date { Date.current.beginning_of_week }
      total_requests { 700 }
      successful_requests { 665 }
      failed_requests { 35 }
    end

    trait :monthly do
      period_type { 'monthly' }
      date { Date.current.beginning_of_month }
      total_requests { 3000 }
      successful_requests { 2850 }
      failed_requests { 150 }
    end

    trait :high_success do
      total_requests { 1000 }
      successful_requests { 990 }
      failed_requests { 10 }
    end

    trait :high_failure do
      total_requests { 1000 }
      successful_requests { 500 }
      failed_requests { 500 }
    end

    trait :no_requests do
      total_requests { 0 }
      successful_requests { 0 }
      failed_requests { 0 }
      avg_duration_ms { nil }
    end

    trait :yesterday do
      date { Date.yesterday }
    end

    trait :last_week do
      date { 1.week.ago.to_date }
    end

    trait :last_month do
      date { 1.month.ago.to_date }
    end
  end
end
