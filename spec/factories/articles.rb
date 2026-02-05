# frozen_string_literal: true

FactoryBot.define do
  factory :article do
    sequence(:title) { |n| "Статья #{n}" }
    excerpt { 'Краткое описание статьи' }
    content { 'Полное содержание статьи с подробной информацией.' }
    association :author, factory: :user
    article_type { :news }
    status { :published }
    featured { false }
    published_at { Time.current }

    trait :news do
      article_type { :news }
    end

    trait :useful_material do
      article_type { :useful_material }
    end

    trait :announcement do
      article_type { :announcement }
    end

    trait :draft do
      status { :draft }
      published_at { nil }
    end

    trait :archived do
      status { :archived }
    end

    trait :featured do
      featured { true }
    end
  end
end
