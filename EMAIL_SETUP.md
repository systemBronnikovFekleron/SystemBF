# Email Setup - Настройка отправки писем

## 📧 Обзор

В платформе реализованы 5 типов email уведомлений:

1. **Приветственное письмо** - после регистрации пользователя
2. **Подтверждение заказа** - при создании нового заказа
3. **Оплата получена** - при успешной оплате заказа
4. **Доступ открыт** - при открытии доступа к продукту
5. **Восстановление пароля** - при запросе сброса пароля

## 🛠 Настройка для Development

### Вариант 1: Letter Opener (рекомендовано для разработки)

Письма открываются в браузере вместо отправки.

1. Добавьте в `Gemfile` (в группу development):

```ruby
group :development do
  gem 'letter_opener'
end
```

2. Установите:

```bash
bundle install
```

3. Настройте в `config/environments/development.rb`:

```ruby
config.action_mailer.delivery_method = :letter_opener
config.action_mailer.perform_deliveries = true
config.action_mailer.default_url_options = { host: 'localhost:3000' }
```

4. Перезапустите сервер.

Теперь все письма будут открываться в браузере!

---

### Вариант 2: Gmail SMTP (для тестирования реальной отправки)

1. Включите двухфакторную аутентификацию в Google аккаунте

2. Создайте **App Password**:
   - Перейдите: https://myaccount.google.com/apppasswords
   - Выберите "Mail" и "Other device"
   - Скопируйте сгенерированный пароль (16 символов)

3. Откройте credentials:

```bash
EDITOR="nano" rails credentials:edit
```

4. Добавьте:

```yaml
smtp:
  username: your-email@gmail.com
  password: YOUR_APP_PASSWORD_HERE
```

5. Настройте `config/environments/development.rb`:

```ruby
config.action_mailer.delivery_method = :smtp
config.action_mailer.smtp_settings = {
  address: 'smtp.gmail.com',
  port: 587,
  user_name: Rails.application.credentials.dig(:smtp, :username),
  password: Rails.application.credentials.dig(:smtp, :password),
  authentication: 'plain',
  enable_starttls_auto: true
}
config.action_mailer.default_url_options = { host: 'localhost:3000' }
config.action_mailer.perform_deliveries = true
```

---

## 🚀 Настройка для Production

### Рекомендуемые провайдеры:

#### 1. SendGrid (рекомендовано)

- **Бесплатно**: 100 писем/день
- **Надежность**: Высокая доставляемость
- **Регистрация**: https://sendgrid.com/

**Настройка:**

```ruby
# config/environments/production.rb
config.action_mailer.delivery_method = :smtp
config.action_mailer.smtp_settings = {
  address: 'smtp.sendgrid.net',
  port: 587,
  user_name: 'apikey',
  password: Rails.application.credentials.dig(:sendgrid, :api_key),
  authentication: 'plain',
  enable_starttls_auto: true
}
config.action_mailer.default_url_options = { host: ENV['APP_HOST'] }
```

**Credentials:**

```yaml
sendgrid:
  api_key: YOUR_SENDGRID_API_KEY
```

---

#### 2. Postmark

- **Бесплатно**: 100 писем/месяц
- **Скорость**: Очень быстрая отправка
- **Регистрация**: https://postmarkapp.com/

**Настройка:**

```ruby
# config/environments/production.rb
config.action_mailer.delivery_method = :smtp
config.action_mailer.smtp_settings = {
  address: 'smtp.postmarkapp.com',
  port: 587,
  user_name: Rails.application.credentials.dig(:postmark, :api_key),
  password: Rails.application.credentials.dig(:postmark, :api_key),
  authentication: 'plain',
  enable_starttls_auto: true
}
config.action_mailer.default_url_options = { host: ENV['APP_HOST'] }
```

**Credentials:**

```yaml
postmark:
  api_key: YOUR_POSTMARK_SERVER_TOKEN
```

---

#### 3. Amazon SES

- **Цена**: $0.10 за 1000 писем
- **Для**: Высоконагруженных проектов
- **Документация**: https://aws.amazon.com/ses/

---

## 📝 Интеграция в код

### 1. Приветственное письмо (после регистрации)

В `app/controllers/registrations_controller.rb`:

```ruby
def create
  @user = User.new(user_params)

  if @user.save
    UserMailer.welcome_email(@user).deliver_later
    redirect_to login_path, notice: 'Регистрация успешна! Проверьте email.'
  else
    render :new, status: :unprocessable_entity
  end
end
```

---

### 2. Подтверждение заказа

В `app/controllers/orders_controller.rb`:

```ruby
def create
  @order = Order.new(order_params)
  @order.user = current_user

  if @order.save
    UserMailer.order_confirmation(@order).deliver_later
    redirect_to new_order_payment_path(@order)
  else
    render :new, status: :unprocessable_entity
  end
end
```

---

### 3. Оплата получена

В `app/controllers/webhooks/cloud_payments_controller.rb`:

```ruby
def pay
  order = Order.find_by(order_number: params[:InvoiceId])

  if order && verify_signature(params)
    order.pay!
    order.update(paid_at: Time.current, payment_id: params[:TransactionId])

    # Send email
    UserMailer.payment_received(order).deliver_later

    render json: { code: 0 }
  else
    render json: { code: 1, error: 'Invalid order or signature' }
  end
end
```

---

### 4. Доступ к продукту открыт

В `app/controllers/order_payments_controller.rb` (или где создается ProductAccess):

```ruby
# После создания ProductAccess
product_access = ProductAccess.create!(user: user, product: product)
UserMailer.product_access_granted(product_access).deliver_later
```

---

### 5. Восстановление пароля

В `app/controllers/password_resets_controller.rb`:

```ruby
def create
  @user = User.find_by(email: params[:email])

  if @user
    # Генерируем токен
    token = SecureRandom.urlsafe_base64
    @user.update(
      reset_password_token: token,
      reset_password_sent_at: Time.current
    )

    # Отправляем email
    UserMailer.password_reset(@user, token).deliver_later

    redirect_to root_path, notice: 'Инструкции отправлены на email'
  else
    flash.now[:alert] = 'Email не найден'
    render :new
  end
end
```

---

## 🧪 Тестирование

### 1. Rails Console

```ruby
rails console

# Отправить приветственное письмо
user = User.first
UserMailer.welcome_email(user).deliver_now

# Отправить подтверждение заказа
order = Order.last
UserMailer.order_confirmation(order).deliver_now
```

---

### 2. Preview в браузере

Создайте `spec/mailers/previews/user_mailer_preview.rb`:

```ruby
class UserMailerPreview < ActionMailer::Preview
  def welcome_email
    UserMailer.welcome_email(User.first)
  end

  def order_confirmation
    UserMailer.order_confirmation(Order.last)
  end

  def payment_received
    UserMailer.payment_received(Order.where(status: :paid).last)
  end

  def product_access_granted
    UserMailer.product_access_granted(ProductAccess.last)
  end

  def password_reset
    user = User.first
    token = 'sample-token-12345'
    UserMailer.password_reset(user, token)
  end
end
```

Откройте: http://localhost:3000/rails/mailers

---

## ⚙️ Environment Variables

Добавьте в `.env` (не коммитить в git!):

```bash
# App Host (для production ссылок в email)
APP_HOST=https://bronnikov.com

# SMTP (если не используете credentials)
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-app-password
```

---

## 📊 Мониторинг отправки

### Solid Queue (уже настроен)

Проверка фоновых задач:

```bash
rails solid_queue:status
```

Если письма не отправляются, проверьте логи:

```bash
tail -f log/development.log
```

---

## ✅ Checklist запуска

- [ ] Установлен SMTP провайдер (SendGrid/Postmark/Gmail)
- [ ] Настроены credentials (rails credentials:edit)
- [ ] Добавлен `APP_HOST` в environment variables
- [ ] Интегрированы вызовы `UserMailer` в контроллеры
- [ ] Протестированы все 5 типов писем
- [ ] Проверена доставляемость (не попадают в Spam)

---

## 🆘 Troubleshooting

### Письма не отправляются

1. Проверьте логи: `tail -f log/development.log`
2. Проверьте Solid Queue: `rails solid_queue:status`
3. Проверьте credentials: `rails runner "p Rails.application.credentials.dig(:smtp)"`

### Письма в Spam

1. Настройте SPF record для домена
2. Настройте DKIM (SendGrid/Postmark делают автоматически)
3. Используйте verified sender domain

### Gmail блокирует отправку

1. Используйте App Password (не обычный пароль)
2. Включите "Less secure app access" (не рекомендуется)
3. Лучше перейти на SendGrid/Postmark

---

## 📚 Дополнительные ресурсы

- [Action Mailer Guide](https://guides.rubyonrails.org/action_mailer_basics.html)
- [SendGrid Ruby Guide](https://docs.sendgrid.com/for-developers/sending-email/rubyonrails)
- [Postmark Rails Guide](https://postmarkapp.com/developer/integration/rails)
