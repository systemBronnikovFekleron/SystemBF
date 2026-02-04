# frozen_string_literal: true

FactoryBot.define do
  factory :order_request do
    association :user
    association :product
    total_kopecks { 100_000 } # Will be overridden by before_create callback
    status { 'pending' }

    trait :approved do
      status { 'approved' }
      approved_at { Time.current }
      association :approved_by, factory: :user
    end

    trait :rejected do
      status { 'rejected' }
      rejected_at { Time.current }
      rejection_reason { 'Недостаточно информации' }
    end

    trait :paid do
      status { 'paid' }
      approved_at { 1.hour.ago }
      paid_at { Time.current }
      payment_method { 'wallet' }
      association :order
    end

    trait :completed do
      status { 'completed' }
      approved_at { 2.hours.ago }
      paid_at { 1.hour.ago }
      payment_method { 'wallet' }
      association :order
    end

    trait :with_form_data do
      form_data do
        {
          'email' => 'user@example.com',
          'first_name' => 'Иван',
          'last_name' => 'Иванов',
          'phone' => '+7 (999) 123-45-67',
          'company_name' => 'ООО "Тестовая компания"'
        }
      end
    end

    trait :auto_approved do
      after(:build) do |request|
        request.product.update(auto_approve: true)
      end
    end
  end
end
