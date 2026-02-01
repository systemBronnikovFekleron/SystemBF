# frozen_string_literal: true

FactoryBot.define do
  factory :category do
    sequence(:name) { |n| "Категория #{n}" }
    description { Faker::Lorem.paragraph }
    position { 0 }
  end
end
