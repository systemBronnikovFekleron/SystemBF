# frozen_string_literal: true

FactoryBot.define do
  factory :sub_role do
    sequence(:name) { |n| "custom_role_#{n}" }
    sequence(:display_name) { |n| "Кастомная роль #{n}" }
    description { 'Тестовая роль' }
    level { 50 }
    system_role { false }

    trait :system do
      name { 'client' }
      display_name { 'Клиент' }
      level { 1 }
      system_role { true }
    end

    trait :guest do
      name { 'guest' }
      display_name { 'Гость' }
      level { 0 }
      system_role { true }
    end

    trait :instructor do
      name { 'instructor_1' }
      display_name { 'Инструктор 1 кат.' }
      level { 5 }
      system_role { true }
    end
  end
end
