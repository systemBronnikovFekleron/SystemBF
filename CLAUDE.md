# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Платформа «Система Бронникова»** - образовательная платформа с JWT-аутентификацией, личным кабинетом, магазином курсов и системой заявок с автоматической обработкой.

**Stack:** Rails 8.1.2 (Ruby 3.3.8) + PostgreSQL + Turbo/Stimulus + Custom CSS Design System
**Status:** Production-ready (155+ тестов, 100% pass rate)

## Common Development Commands

### Server & Database
```bash
rails s                  # Запуск сервера (localhost:3000)
rails db:migrate         # Миграции
rails db:seed            # Демо-данные (5 users, 7 products)
rails c                  # Rails консоль
```

### Testing
```bash
bundle exec rspec                              # Все тесты (155+)
bundle exec rspec spec/models/user_spec.rb:15  # Конкретный тест
COVERAGE=true bundle exec rspec                # С покрытием
```

### Code Quality
```bash
bundle exec rubocop      # Проверка стиля (omakase)
bundle exec rubocop -a   # Автоисправление
bundle exec brakeman     # Безопасность
```

## Critical Architecture Patterns

### 1. Money Handling (КРИТИЧНО!)

**ВСЕ денежные суммы в копейках (integer), НИКОГДА decimals:**

```ruby
# Поля в моделях
price_kopecks: integer           # Product
total_kopecks: integer           # Order, OrderRequest
balance_kopecks: integer         # Wallet
amount_kopecks: integer          # WalletTransaction

# Конвертация через money-rails
monetize :price_kopecks, as: :price, with_currency: :rub
product.price_kopecks  # → 99900 (integer)
product.price          # → Money объект (999,00 ₽)
```

### 2. Wallet Operations (КРИТИЧНО для транзакций!)

**ВСЕГДА используйте методы с lock! и audit trail:**

```ruby
# ✅ ПРАВИЛЬНО - с pessimistic lock и WalletTransaction
wallet.deposit_with_transaction(amount_kopecks, order_request = nil)
wallet.withdraw_with_transaction(amount_kopecks, order_request = nil)
wallet.refund_with_transaction(amount_kopecks, order_request = nil)

# ❌ НЕПРАВИЛЬНО - race conditions!
wallet.update(balance_kopecks: new_balance)
```

**Особенности реализации:**
- `lock!` внутри transaction блокирует запись
- Создаёт `WalletTransaction` с `balance_before` и `balance_after`
- Хранит отрицательные суммы для withdrawals

### 3. AASM Callbacks Timing (КРИТИЧНО!)

**ВАЖНО:** AASM `after:` callbacks выполняются ДО сохранения в БД!

```ruby
# ❌ НЕ РАБОТАЕТ
event :approve do
  transitions from: :pending, to: :approved, after: :do_something
end

def do_something
  pay! if may_pay?  # FAIL! Статус в памяти = approved, но в БД = pending
end

# ✅ РАБОТАЕТ - используйте after_commit
after_commit :do_something_after_approve, if: :saved_change_to_approved?

def saved_change_to_approved?
  saved_change_to_status? && status == 'approved'
end

def do_something_after_approve
  pay! if may_pay?  # OK! Статус уже в БД
end
```

**Примеры в кодовой базе:**
- `OrderRequest#process_auto_payment` - через `after_commit`
- `OrderRequest#auto_complete` - через `after_save` с флагом `@should_auto_complete`
- `Initiation#grant_sub_roles_on_completion` - через `after_commit`

### 4. Auto-Created Associations

**При создании User автоматически создаются:**
- `Profile` (пустой)
- `Wallet` (balance_kopecks = 0)
- `Rating` (points = 0, level = 1)

```ruby
# app/models/user.rb
after_create :create_associated_records

def create_associated_records
  create_profile
  create_wallet
  create_rating
end
```

**НЕ создавайте вручную в контроллерах!**

### 5. Enum Prefixes (КРИТИЧНО!)

```ruby
# User classification (14 типов: guest, client, ..., admin)
enum :classification, { guest: 0, client: 1, ..., admin: 13 }, prefix: true

# ✅ ПРАВИЛЬНО
user.classification_admin?           # С префиксом
user.classification_center_director? # С префиксом
user.admin_role?                     # Custom метод для admin/manager/curator

# ❌ НЕПРАВИЛЬНО
user.admin?                          # НЕ СУЩЕСТВУЕТ!
```

**Другие enums:**
- `Order`: `status_paid?` (с префиксом)
- `Product`: `Product.published` (scope, БЕЗ префикса)
- `WalletTransaction`: `transaction_type_withdrawal?` (с префиксом)

### 6. Layout Switching

**Автоматическое переключение:**

```ruby
# ApplicationController
layout :layout_by_authentication

def layout_by_authentication
  return 'application' if controller_name.in?(['sessions', 'registrations', 'password_resets'])
  logged_in? ? 'dashboard' : 'application'
end
```

**Важно:**
- ВСЕ авторизованные пользователи видят `dashboard` layout (включая главную, каталог, события)
- `application` layout только для входа/регистрации и неавторизованных
- Dashboard layout имеет sidebar с высотой header = 89px

### 7. OrderRequest Auto-Approval Flow

**Если `product.auto_approve = true` и достаточно средств:**

```
1. pending
2. approve! (автоматически)
3. after_commit → process_auto_payment
4. wallet.withdraw_with_transaction
5. pay!
6. create_order_and_grant_access
7. @should_auto_complete = true
8. after_save → auto_complete_if_paid
9. complete! → completed ✅
```

**Ключевые моменты:**
- Instance variable `@should_auto_complete` управляет flow
- Используются 3 типа callbacks: `after_create`, `after_commit`, `after_save`
- Автоматическая выдача SubRoles через `product.auto_grant_sub_roles`

### 8. User Impersonation

**JWT содержит metadata:**

```ruby
payload = {
  user_id: impersonated_user.id,
  impersonator_id: admin.id,
  impersonation_session_token: session_token
}
```

**Проверка в `current_user`:**
- Если `impersonator_id` присутствует → проверяет `ImpersonationLog`
- Максимальная длительность: 4 часа
- Если сессия истекла → автоматически удаляет cookies
- Админка ЗАБЛОКИРОВАНА во время имперсонации

### 9. SubRole System (параллельно classification)

**Независимая система ролей:**

```ruby
# Выдача роли с tracking
user.grant_sub_role!(
  'advanced_student',
  granted_by: instructor,
  granted_via: 'initiation_completed',  # или 'product_purchase', 'manual'
  source: initiation                     # Полиморфная ссылка
)

# Массовая выдача (используется в auto-grant)
user.grant_sub_roles!(['role1', 'role2'], ...)

# Проверка
user.has_sub_role?('advanced_student')
user.active_sub_roles  # scope: не истёкшие
```

**Auto-grant триггеры:**
- При покупке продукта → `product.auto_grant_sub_roles`
- При завершении инициации → `initiation.auto_grant_sub_roles`

### 10. Profile vs User Fields (КРИТИЧНО!)

**User model:**
- `first_name`, `last_name`, `email`, `password_digest`, `classification`

**Profile model:**
- `phone`, `birth_date`, `bio`, `city`, `country`
- НЕ содержит: `first_name`, `last_name`

```erb
<!-- ✅ ПРАВИЛЬНО -->
<%= form.text_field "first_name", value: @user.first_name %>
<%= form.text_field "profile[phone]", value: @user.profile.phone %>

<!-- ❌ НЕПРАВИЛЬНО -->
<%= form.text_field "profile[first_name]" %> <!-- не существует! -->
```

## Core Models Architecture

### User System
- `User` - 14 classification types (0: guest → 13: admin)
- `Profile` - extended info (auto-created)
- `Wallet` - internal wallet in kopecks (auto-created)
- `Rating` - gamification (auto-created)
- `SubRole` + `UserSubRole` - independent role system with expiration
- `ImpersonationLog` - admin impersonation tracking

### Shop System
- `Category` - with FriendlyId slug
- `Product` - 5 types (video_course, book, course, service, event)
  - AASM: `draft` → `published` → `archived`
  - `auto_approve` boolean для автоматического одобрения
  - `auto_grant_sub_roles` array для автовыдачи ролей
- `Order` - AASM: `pending` → `paid` / `cancelled` / `refunded`
- `OrderItem` - line items
- `ProductAccess` - auto-granted after payment

### Order Request System (ключевая фича)
- `OrderRequest` - заявки с модерацией или auto-approval
  - AASM: `pending` → `approved` → `paid` → `completed` / `cancelled` / `rejected`
  - `process_auto_payment` если `product.auto_approve = true`
- `WalletTransaction` - audit trail для всех операций (deposit/withdrawal/refund)

### Development System
- `Initiation` - инициации (first, second, third, advanced)
- `Diagnostic` - диагностики (vision, bioenergy, psychobiocomputer)
- `Event` - события с регистрацией
- `EventRegistration` - связь user ↔ event

### Content System
- `Article` - новости/статьи с FriendlyId
- `WikiPage` - база знаний (иерархическая структура)
- `Favorite` - полиморфная связь (Product, Article, WikiPage)

## Authentication & Authorization

**JWT Authentication** (`app/services/json_web_token.rb`):
- Encode: `JsonWebToken.encode(payload, exp)` (по умолчанию 24h)
- Decode: `JsonWebToken.decode(token)` → HashWithIndifferentAccess или nil

**Поддержка двух методов:**
- Web: `cookies.encrypted[:jwt_token]`
- API: `Authorization: Bearer <token>` header

**Helpers:** `current_user`, `logged_in?`, `authenticate_user!`

**Authorization (Pundit):**
- `app/policies/application_policy.rb` - базовая
- `app/policies/admin_policy.rb` - проверяет `user.admin_role?`
- Использование: `authorize @resource`

## Routes Structure

**Web:** `/`, `/login`, `/register`, `/products`, `/events`, `/dashboard/*`
**API:** `/api/v1/login`, `/api/v1/logout`, `/api/v1/validate_token`
**Admin:** `/admin/*` (requires `admin_role?`)
**Webhooks:** `/webhooks/cloudpayments/*` (HMAC-verified)

## Testing

**155+ тестов (RSpec + FactoryBot):**
- Model specs: 131 тест (validations, associations, scopes)
- Request specs: 76+ тестов (dashboard, admin, webhooks, mailers)
- Helpers: `spec/support/auth_helpers.rb`

```ruby
# Для request specs
sign_in(user)                              # Web cookies
api_sign_in(user)                          # API header
generate_cloudpayments_signature(order)    # HMAC verification
```

## Performance

**Implemented:**
- Eager loading: `Product.includes(:category)`
- Fragment caching: products, dashboard
- Database indexes: 100% coverage (все foreign keys)
- Query optimization: `pluck`, `exists?`, `find_each`

**Results:**
- GET /products: -88% queries (25 → 3)
- GET /dashboard: -82% queries (40 → 7)

## Common Issues & Solutions

### 1. Bullet N+1 Warnings
Удалите избыточный `.includes()` если ассоциация не используется в view.

### 2. Division by Zero
```erb
<!-- ✅ С проверкой -->
<%= @user.rating.points > 0 ? (item[:points].to_f / @user.rating.points * 100).round : 0 %>%
```

### 3. Helper Methods Not Found
Переместите в `app/helpers/application_helper.rb`, не в views.

### 4. Logout Not Working
Используйте `logout_path` (НЕ `/api/v1/logout`).

### 5. Turbo Form Issues
Отключите для форм логина: `data: { turbo: false }`.

## Development Guidelines

1. **Money в копейках** - ВСЕГДА integer, НИКОГДА decimals
2. **Enum префиксы** - `classification_admin?` НЕ `admin?`
3. **Wallet operations** - используйте `*_with_transaction` методы
4. **AASM timing** - `after_commit` для операций после сохранения
5. **Russian language** - все сообщения, flash notices, email на русском
6. **Rails 8 defaults** - Solid Queue/Cache/Cable, Propshaft, Import Maps
7. **Security** - параметризованные запросы, Strong Parameters ВСЕГДА
8. **Testing** - RSpec model + request specs для всех фич
9. **Performance** - `includes` для N+1 prevention, pagination, caching
10. **Frontend** - Turbo Frames/Streams first, минимум Stimulus JS

## Code Style

- **Format**: 2 spaces, 80-100 chars/line, `# frozen_string_literal: true`
- **Naming**: snake_case (methods), CamelCase (classes), SCREAMING_SNAKE_CASE (constants)
- **Migrations**: НИКОГДА не редактируйте schema.rb вручную
- **RuboCop**: omakase style (`bundle exec rubocop -a`)

## Demo Data

После `rails db:seed`:

| Email | Пароль | Classification | Баланс |
|-------|--------|----------------|--------|
| admin@bronnikov.com | password123 | admin | 10,000 ₽ |
| director@bronnikov.com | password123 | center_director | 5,000 ₽ |
| specialist@bronnikov.com | password123 | specialist | 3,000 ₽ |
| client@example.com | password123 | client | 1,000 ₽ |
| guest@example.com | password123 | guest | 0 ₽ |

## Additional Documentation

- `TESTING_GUIDE.md` - test stack, helpers, 155+ tests
- `PERFORMANCE_GUIDE.md` - Bullet, indexes, caching
- `EMAIL_SETUP.md` - SMTP, Letter Opener
- `GOOGLE_ANALYTICS_SETUP.md` - GA4, e-commerce tracking
- `PROJECT_STATUS.md` - roadmap, deployment checklist
- `AIDocs/FRONTEND.md` - Design System (glassmorphism, gradients)
- `AIDocs/API.md` - REST API documentation
- `WORDPRESS_SSO_GUIDE.md` - WordPress SSO plugin
- `TELEGRAM_BOT_GUIDE.md` - Telegram bot integration

## Notes

- Platform serves Russian-speaking audience
- Compliance with Russian data protection laws (152-ФЗ)
- All monetary operations in RUB (копейки for precision)
- JWT tokens expire через 24 часа
- Rails 8 defaults: Solid Queue, Solid Cache, Solid Cable, Propshaft
- Production-ready: 155+ tests, 0 security issues, optimized performance
