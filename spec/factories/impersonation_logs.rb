# frozen_string_literal: true

FactoryBot.define do
  factory :impersonation_log do
    association :admin, factory: [:user, :admin]
    association :user, factory: :user
    session_token { SecureRandom.uuid }
    started_at { Time.current }
    ip_address { '127.0.0.1' }
    user_agent { 'Mozilla/5.0' }

    trait :active do
      ended_at { nil }
    end

    trait :ended do
      ended_at { 1.hour.from_now }
    end

    trait :expired do
      started_at { (ImpersonationLog::MAX_DURATION_HOURS + 1).hours.ago }
      ended_at { nil }
    end
  end
end
