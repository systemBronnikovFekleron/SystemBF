# frozen_string_literal: true

FactoryBot.define do
  factory :product do
    association :category
    sequence(:name) { |n| "Продукт #{n}" }
    description { Faker::Lorem.paragraph }
    price_kopecks { rand(10000..100000) } # от 100 до 1000 руб
    product_type { :course }
    status { :draft }
    featured { false }
    position { 0 }

    trait :published do
      status { :published }
    end

    trait :archived do
      status { :archived }
    end

    trait :featured do
      featured { true }
    end

    trait :video do
      product_type { :video }
    end

    trait :book do
      product_type { :book }
    end

    trait :service do
      product_type { :service }
    end
  end
end
