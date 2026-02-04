# frozen_string_literal: true

puts "Создание email шаблонов..."

# Welcome Email
EmailTemplate.find_or_create_by!(template_key: 'welcome_email') do |template|
  template.name = 'Приветственное письмо'
  template.category = 'user'
  template.subject = 'Добро пожаловать в Систему Бронникова, {{user_name}}!'
  template.body_html = <<~HTML
    <h1>Здравствуйте, {{user_name}}!</h1>
    <p>Мы рады приветствовать вас в <strong>Системе Бронникова</strong> – образовательной платформе для развития интуиции и сверхвозможностей человека.</p>

    <h2>Что вас ждет:</h2>
    <ul>
      <li>Доступ к уникальным видеокурсам и материалам</li>
      <li>Возможность записаться на мероприятия и тренинги</li>
      <li>Персональный кабинет с историей обучения</li>
      <li>Система достижений и рейтингов</li>
    </ul>

    <p>Ваш email: <strong>{{user_email}}</strong></p>

    <p style="margin-top: 30px;">
      <a href="{{url}}" style="background: #4F46E5; color: white; padding: 12px 24px; text-decoration: none; border-radius: 8px; display: inline-block;">
        Перейти в личный кабинет
      </a>
    </p>

    <p style="margin-top: 40px; color: #64748b; font-size: 14px;">
      С уважением,<br>
      Команда Системы Бронникова
    </p>
  HTML
  template.body_text = <<~TEXT
    Здравствуйте, {{user_name}}!

    Мы рады приветствовать вас в Системе Бронникова – образовательной платформе для развития интуиции и сверхвозможностей человека.

    Что вас ждет:
    - Доступ к уникальным видеокурсам и материалам
    - Возможность записаться на мероприятия и тренинги
    - Персональный кабинет с историей обучения
    - Система достижений и рейтингов

    Ваш email: {{user_email}}

    Перейти в личный кабинет: {{url}}

    С уважением,
    Команда Системы Бронникова
  TEXT
  template.available_variables = ['user_name', 'user_email', 'url']
  template.active = true
  template.system_default = true
  template.sent_count = rand(50..200)
  template.last_sent_at = rand(1..48).hours.ago
end

# Order Confirmation
EmailTemplate.find_or_create_by!(template_key: 'order_confirmation') do |template|
  template.name = 'Подтверждение заказа'
  template.category = 'order'
  template.subject = 'Заказ {{order_number}} подтвержден'
  template.body_html = <<~HTML
    <h1>Заказ подтвержден!</h1>
    <p>Здравствуйте, {{user_name}}!</p>

    <p>Ваш заказ <strong>№{{order_number}}</strong> успешно оформлен и оплачен.</p>

    <div style="background: #f8fafc; padding: 20px; border-radius: 8px; margin: 20px 0;">
      <h3 style="margin-top: 0;">Детали заказа:</h3>
      <p><strong>Продукт:</strong> {{product_name}}</p>
      <p><strong>Сумма:</strong> {{price}}</p>
      <p><strong>Дата:</strong> {{date}}</p>
    </div>

    <p>Доступ к материалам открыт в вашем личном кабинете.</p>

    <p style="margin-top: 30px;">
      <a href="{{url}}" style="background: #16a34a; color: white; padding: 12px 24px; text-decoration: none; border-radius: 8px; display: inline-block;">
        Перейти к продукту
      </a>
    </p>
  HTML
  template.body_text = <<~TEXT
    Заказ подтвержден!

    Здравствуйте, {{user_name}}!

    Ваш заказ №{{order_number}} успешно оформлен и оплачен.

    Детали заказа:
    Продукт: {{product_name}}
    Сумма: {{price}}
    Дата: {{date}}

    Доступ к материалам открыт в вашем личном кабинете.

    Перейти к продукту: {{url}}
  TEXT
  template.available_variables = ['user_name', 'order_number', 'product_name', 'price', 'date', 'url']
  template.active = true
  template.system_default = true
  template.sent_count = rand(100..500)
  template.last_sent_at = rand(1..24).hours.ago
end

# Password Reset
EmailTemplate.find_or_create_by!(template_key: 'password_reset') do |template|
  template.name = 'Восстановление пароля'
  template.category = 'user'
  template.subject = 'Восстановление пароля для {{user_email}}'
  template.body_html = <<~HTML
    <h1>Восстановление пароля</h1>
    <p>Здравствуйте, {{user_name}}!</p>

    <p>Вы запросили восстановление пароля для вашей учетной записи.</p>

    <p style="margin: 30px 0;">
      <a href="{{reset_url}}" style="background: #4F46E5; color: white; padding: 12px 24px; text-decoration: none; border-radius: 8px; display: inline-block;">
        Сбросить пароль
      </a>
    </p>

    <p style="color: #dc2626; font-weight: 600;">⚠️ Ссылка действительна в течение 2 часов.</p>

    <p style="margin-top: 30px; color: #64748b; font-size: 14px;">
      Если вы не запрашивали восстановление пароля, просто проигнорируйте это письмо.
    </p>
  HTML
  template.body_text = <<~TEXT
    Восстановление пароля

    Здравствуйте, {{user_name}}!

    Вы запросили восстановление пароля для вашей учетной записи.

    Для сброса пароля перейдите по ссылке: {{reset_url}}

    ⚠️ Ссылка действительна в течение 2 часов.

    Если вы не запрашивали восстановление пароля, просто проигнорируйте это письмо.
  TEXT
  template.available_variables = ['user_name', 'user_email', 'reset_url']
  template.active = true
  template.system_default = true
  template.sent_count = rand(20..100)
  template.last_sent_at = rand(1..72).hours.ago
end

# Product Access Granted
EmailTemplate.find_or_create_by!(template_key: 'product_access_granted') do |template|
  template.name = 'Доступ к продукту предоставлен'
  template.category = 'product'
  template.subject = 'Доступ к {{product_name}} открыт!'
  template.body_html = <<~HTML
    <h1>Доступ предоставлен!</h1>
    <p>Здравствуйте, {{user_name}}!</p>

    <p>Вам предоставлен доступ к продукту: <strong>{{product_name}}</strong></p>

    <p>Теперь вы можете приступить к обучению прямо сейчас!</p>

    <p style="margin-top: 30px;">
      <a href="{{product_url}}" style="background: #9333EA; color: white; padding: 12px 24px; text-decoration: none; border-radius: 8px; display: inline-block;">
        Начать обучение
      </a>
    </p>

    <p style="margin-top: 40px; color: #64748b; font-size: 14px;">
      Желаем успехов в освоении материала!
    </p>
  HTML
  template.body_text = <<~TEXT
    Доступ предоставлен!

    Здравствуйте, {{user_name}}!

    Вам предоставлен доступ к продукту: {{product_name}}

    Теперь вы можете приступить к обучению прямо сейчас!

    Начать обучение: {{product_url}}

    Желаем успехов в освоении материала!
  TEXT
  template.available_variables = ['user_name', 'product_name', 'product_url']
  template.active = true
  template.system_default = false
  template.sent_count = rand(80..400)
  template.last_sent_at = rand(1..36).hours.ago
end

puts "✅ Создано #{EmailTemplate.count} email шаблонов"
