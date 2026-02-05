# frozen_string_literal: true

FactoryBot.define do
  factory :event do
    sequence(:title) { |n| "Мероприятие #{n}" }
    description { 'Описание мероприятия' }
    starts_at { 1.week.from_now }
    ends_at { 1.week.from_now + 2.hours }
    location { 'Москва, ул. Примерная, 1' }
    is_online { false }
    max_participants { 30 }
    price_kopecks { 500000 }
    status { :published }
    auto_approve { true }
    association :category
    association :organizer, factory: :user

    trait :online do
      is_online { true }
      location { nil }
    end

    trait :free do
      price_kopecks { 0 }
    end

    trait :draft do
      status { :draft }
    end

    trait :cancelled do
      status { :cancelled }
    end

    trait :completed do
      status { :completed }
      starts_at { 1.week.ago }
      ends_at { 1.week.ago + 2.hours }
    end

    trait :unlimited_seats do
      max_participants { nil }
    end

    trait :full do
      after(:create) do |event|
        create_list(:event_registration, event.max_participants, event: event, status: :confirmed)
      end
    end
  end
end
