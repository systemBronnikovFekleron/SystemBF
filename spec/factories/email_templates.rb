# frozen_string_literal: true

FactoryBot.define do
  factory :email_template do
    sequence(:template_key) { |n| "template_#{n}" }
    name { 'Test Email Template' }
    category { 'user' }
    subject { 'Привет, {{user_name}}!' }
    body_html { '<p>Добро пожаловать, {{user_name}}!</p><p>Ваш email: {{user_email}}</p>' }
    body_text { 'Добро пожаловать, {{user_name}}! Ваш email: {{user_email}}' }
    available_variables { ['user_name', 'user_email'] }
    active { true }
    system_default { false }

    trait :user_category do
      category { 'user' }
      name { 'Приветственное письмо' }
      template_key { 'welcome_email' }
      subject { 'Добро пожаловать в Систему Бронникова, {{user_name}}!' }
      body_html do
        <<~HTML
          <h1>Здравствуйте, {{user_name}}!</h1>
          <p>Благодарим за регистрацию в Системе Бронникова.</p>
          <p>Ваш email: {{user_email}}</p>
        HTML
      end
      available_variables { ['user_name', 'user_email'] }
    end

    trait :order_category do
      category { 'order' }
      name { 'Подтверждение заказа' }
      template_key { 'order_confirmation' }
      subject { 'Заказ {{order_number}} подтвержден' }
      body_html do
        <<~HTML
          <h1>Заказ {{order_number}}</h1>
          <p>Здравствуйте, {{user_name}}!</p>
          <p>Ваш заказ на сумму {{price}} подтвержден.</p>
          <p>Товар: {{product_name}}</p>
        HTML
      end
      available_variables { ['user_name', 'order_number', 'price', 'product_name'] }
    end

    trait :product_category do
      category { 'product' }
      name { 'Доступ к продукту' }
      template_key { 'product_access' }
      subject { 'Доступ к {{product_name}}' }
      body_html do
        <<~HTML
          <h1>Доступ предоставлен</h1>
          <p>Здравствуйте, {{user_name}}!</p>
          <p>Вам предоставлен доступ к продукту: {{product_name}}</p>
        HTML
      end
      available_variables { ['user_name', 'product_name'] }
    end

    trait :system_category do
      category { 'system' }
      name { 'Системное уведомление' }
      template_key { 'system_notification' }
      subject { 'Системное уведомление' }
      body_html do
        <<~HTML
          <h1>Системное уведомление</h1>
          <p>{{message}}</p>
        HTML
      end
      available_variables { ['message'] }
    end

    trait :system do
      system_default { true }
    end

    trait :inactive do
      active { false }
    end

    trait :with_usage do
      sent_count { 50 }
      last_sent_at { 1.hour.ago }
    end
  end
end
