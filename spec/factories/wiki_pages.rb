# frozen_string_literal: true

FactoryBot.define do
  factory :wiki_page do
    sequence(:title) { |n| "Wiki страница #{n}" }
    content { 'Содержание wiki страницы' }
    association :created_by, factory: :user
    association :updated_by, factory: :user
    parent { nil }
    position { 0 }
    status { :published }

    trait :draft do
      status { :draft }
    end

    trait :with_children do
      after(:create) do |page|
        create_list(:wiki_page, 3, parent: page)
      end
    end
  end
end
