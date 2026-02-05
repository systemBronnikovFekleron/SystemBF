# frozen_string_literal: true

FactoryBot.define do
  factory :event_registration do
    association :user
    association :event
    registered_at { Time.current }
    status { :pending }
    notes { nil }

    trait :confirmed do
      status { :confirmed }
    end

    trait :attended do
      status { :attended }
    end

    trait :cancelled do
      status { :cancelled }
    end

    trait :with_order do
      association :order
    end
  end
end
