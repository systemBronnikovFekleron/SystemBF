# frozen_string_literal: true

FactoryBot.define do
  factory :favorite do
    association :user
    association :favoritable, factory: :product

    trait :product do
      association :favoritable, factory: :product
    end

    trait :article do
      association :favoritable, factory: :article
    end

    trait :wiki_page do
      association :favoritable, factory: :wiki_page
    end
  end
end
