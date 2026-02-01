# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    email { Faker::Internet.unique.email }
    password { 'password123' }
    password_confirmation { 'password123' }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    classification { :client }
    active { true }

    trait :guest do
      classification { :guest }
    end

    trait :club_member do
      classification { :club_member }
    end

    trait :representative do
      classification { :representative }
    end

    trait :instructor do
      classification { :instructor_1 }
    end

    trait :specialist do
      classification { :specialist }
    end

    trait :center_director do
      classification { :center_director }
    end

    trait :admin do
      classification { :admin }
    end

    trait :inactive do
      active { false }
    end
  end
end
