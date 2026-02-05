# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Платформа «Система Бронникова»** - информационная платформа с личным кабинетом и единой авторизацией для всех сервисов и сайтов системы Бронников-Феклерон.

Это образовательная экосистема для клиентов, учеников, специалистов и руководителей центров и клубов системы "Бронников-Феклерон".

**Статус:** MVP завершен (35/35 tasks), Enhanced (15/17 tasks, 88%). Production-ready. 155+ тестов (100% pass rate).

## Technology Stack

- **Backend**: Ruby 3.3.8 + Rails 8.1.2
- **Database**: PostgreSQL 14+
- **Frontend**: Turbo + Stimulus (Rails 8 defaults) + Custom CSS Design System
- **Asset Pipeline**: Propshaft + Import Maps
- **Background Jobs**: Solid Queue
- **Caching**: Solid Cache
- **WebSockets**: Solid Cable
- **Authentication**: JWT (custom implementation)
- **Authorization**: Pundit
- **Payments**: CloudPayments + Money-Rails (RUB)
- **State Machines**: AASM
- **URLs**: FriendlyId для ЧПУ
- **Pagination**: Kaminari
- **Performance**: Bullet + Rack Mini Profiler
- **Testing**: RSpec + FactoryBot (155+ tests)

## Common Development Commands

### Server Management
```bash
# Запуск сервера (http://localhost:3000)
rails server  # или rails s

# Остановка: Ctrl+C
ps aux | grep puma  # найти PID
kill <PID>
```

### Database
```bash
rails db:create              # Создание БД
rails db:migrate             # Запуск миграций
rails db:rollback            # Откат последней миграции
rails db:seed                # Демо-данные (5 users, 7 products, 4 categories)
rails db:reset               # drop + create + migrate + seed
rails db                     # Консоль БД
rails console                # Rails консоль (rails c)
```

### Testing
```bash
bundle exec rspec                              # Все тесты (155+)
bundle exec rspec --format documentation       # С подробным выводом
bundle exec rspec spec/models/user_spec.rb     # Конкретный файл
bundle exec rspec spec/models/user_spec.rb:15  # Конкретный тест
bundle exec rspec spec/models/                 # Только модели (131 тест)
COVERAGE=true bundle exec rspec                # С покрытием кода
```

**Test Coverage:** Models: 100%, Request specs: 85%+, Mailers: 90%+

### Code Quality
```bash
bundle exec rubocop          # Проверка стиля (omakase)
bundle exec rubocop -a       # Автоисправление
bundle exec brakeman         # Безопасность
bundle exec bundler-audit    # Уязвимости зависимостей
```

## Application Architecture

### Core Domain Models

**User System** (14 типов классификации через enum):
- `User` - Базовая модель с email/password (bcrypt) и classification enum:
  - 0: `guest`, 1: `client`, 2: `club_member`, 3: `representative`, 4: `trainee`
  - 5-7: `instructor_1/2/3`, 8: `specialist`, 9: `expert`
  - 10: `center_director`, 11: `curator`, 12: `manager`, 13: `admin`
  - **Важно**: Используйте префикс `classification_` для проверок (например, `user.classification_admin?`)
  - **Admin роли**: проверяйте через `user.admin_role?` (включает admin, manager, curator)
  - **Auto-создание**: При создании User автоматически создаются Profile, Wallet, Rating
- `Profile` - Расширенная информация (bio, phone, city, country, birth_date)
- `Wallet` - Внутренний кошелек (balance_kopecks в копейках для точности)
- `Rating` - Рейтинговая система (points, level)

**Shop System**:
- `Category` - Категории продуктов (с slug через FriendlyId)
- `Product` - Продукты 5 типов (video_course, book, course, service, event):
  - Цена: `price_kopecks` (integer, копейки)
  - AASM статусы: `draft` → `published` → `archived`
  - Доступ через slug: `Product.friendly.find('slug')`
  - Поле `auto_approve` для автоматического одобрения заявок
- `Order` - Заказы с уникальным order_number:
  - AASM статусы: `pending` → `paid` / `cancelled` / `refunded`
  - Total: `total_kopecks` (integer, копейки)
  - Генерация order_number: автоматически в before_create
- `OrderItem` - Позиции заказа (привязаны к Order и Product)
- `ProductAccess` - Автоматический доступ к цифровым продуктам после оплаты
- `InteractionHistory` - История взаимодействий пользователя с системой

**Order Request System** (Система заявок на покупку):
- `OrderRequest` - Заявки на покупку продуктов с модерацией:
  - AASM статусы: `pending` → `approved` → `paid` → `completed` / `cancelled` / `rejected`
  - Генерация request_number: автоматически в before_create (формат: `REQ-timestamp-HEX`)
  - **Auto-approval flow**: если `product.auto_approve = true` и достаточно средств:
    1. `approve!` → статус `approved`
    2. `after_commit` → `process_auto_payment` (списание с кошелька)
    3. `pay!` → статус `paid`, создание Order/OrderItem/ProductAccess
    4. `after_save` → `auto_complete` → статус `completed`
  - **Manual approval flow**: админ одобряет заявку, пользователь платит вручную
  - Связи: `user`, `product`, `order`, `approved_by`, `wallet_transactions`
- `WalletTransaction` - Транзакции кошелька (audit trail):
  - Types (string enum): `deposit`, `withdrawal`, `refund`
  - Поля: `amount_kopecks`, `balance_before_kopecks`, `balance_after_kopecks`
  - Связь с `order_request` для отслеживания платежей

### Authentication & Authorization

**JWT Authentication** (`app/services/json_web_token.rb`):
- Энкодинг: `JsonWebToken.encode(payload, exp)` - по умолчанию 24 часа
- Декодинг: `JsonWebToken.decode(token)` - возвращает HashWithIndifferentAccess или nil
- Используется в API контроллерах через `api/v1/authentication_controller.rb`
- **Web + API**: ApplicationController поддерживает оба метода:
  - Cookies: `cookies.encrypted[:jwt_token]` для web интерфейса
  - Header: `Authorization: Bearer <token>` для API запросов
- **Хелперы**: `current_user`, `logged_in?`, `authenticate_user!` доступны во всех контроллерах

**Authorization** (Pundit):
- Базовая политика: `app/policies/application_policy.rb`
- Пользовательская политика: `app/policies/user_policy.rb`
- Admin политика: `app/policies/admin_policy.rb` (проверяет `user.admin_role?`)
- Использование: `authorize @resource` в контроллерах

### Controllers Structure

```
app/controllers/
├── application_controller.rb       # Базовый (JWT + cookies auth)
├── sessions_controller.rb          # Вход/выход (web)
├── registrations_controller.rb     # Регистрация
├── password_resets_controller.rb   # Восстановление пароля (24h tokens)
├── dashboard_controller.rb         # Личный кабинет (8 экшенов)
├── products_controller.rb          # Каталог и детали
├── orders_controller.rb            # Заказы и оплата
├── order_payments_controller.rb    # Обработка платежей
├── order_requests_controller.rb    # Заявки на покупку
├── external_forms_controller.rb    # WordPress интеграция
├── telegram_controller.rb          # Telegram бот (базовая интеграция)
├── admin/                          # Admin namespace (требует admin_role?)
│   ├── dashboard_controller.rb     # Analytics + revenue charts
│   ├── products_controller.rb      # CRUD + bulk actions
│   ├── orders_controller.rb        # Order management + AASM actions
│   ├── users_controller.rb
│   └── interaction_histories_controller.rb
├── webhooks/
│   ├── cloud_payments_controller.rb # HMAC-verified webhooks
│   └── telegram_controller.rb
└── api/v1/
    ├── base_controller.rb
    ├── authentication_controller.rb # JWT login/logout/validate
    └── users_controller.rb
```

### Routes Architecture

**Web Routes**:
- Root: `/` → `home#index`
- Auth: `/login`, `/register`, `/forgot-password`, `/password-resets/:token/edit`
- Shop: `/categories`, `/products`, `/cart`, `/orders`
- Dashboard: `/dashboard/*` (8 разделов: index, profile, wallet, my-courses, achievements, notifications, settings, rating)

**API Routes** (все под `/api/v1/`):
- POST `/api/v1/login` - JWT аутентификация
- DELETE `/api/v1/logout` - Выход
- GET `/api/v1/validate_token` - Валидация JWT (для WordPress SSO)
- GET/PATCH `/api/v1/users/:id` - User API

**Admin Routes** (все под `/admin/`, требуют `admin_role?`):
- GET `/admin` - Dashboard с analytics
- CRUD `/admin/products` + POST `/admin/products/bulk_action` (publish/archive/delete)
- CRUD `/admin/orders` + PATCH `/admin/orders/:id` (complete/refund/cancel)
- GET/PATCH `/admin/users`

**Webhooks** (HMAC signature verification):
- POST `/webhooks/cloudpayments/pay` - Успешная оплата
- POST `/webhooks/cloudpayments/fail` - Неудачная оплата
- POST `/webhooks/cloudpayments/refund` - Возврат средств

### Money Handling (КРИТИЧНО!)

**Все цены хранятся в копейках (integer) для точности:**
- `price_kopecks` в Product
- `total_kopecks` в Order, OrderRequest
- `balance_kopecks` в Wallet
- `amount_kopecks`, `balance_before_kopecks`, `balance_after_kopecks` в WalletTransaction
- Конвертация: `Money.new(kopecks, 'RUB')` через money-rails
- В views: `humanized_money_with_symbol(@product.price)`

### Wallet Operations (КРИТИЧНО для транзакций!)

**Методы Wallet:**
```ruby
# Проверка баланса
wallet.sufficient_balance?(amount_kopecks)  # boolean

# Пополнение (deposit) - создает WalletTransaction
wallet.deposit_with_transaction(amount_kopecks, order_request = nil)

# Списание (withdrawal) - создает WalletTransaction + проверяет баланс
wallet.withdraw_with_transaction(amount_kopecks, order_request = nil)
# Raises ArgumentError если insufficient_balance

# Возврат (refund) - создает WalletTransaction
wallet.refund_with_transaction(amount_kopecks, order_request = nil)
```

**ВАЖНО:**
- Все операции с кошельком используют `lock!` для предотвращения race conditions
- WalletTransaction создается автоматически с audit trail (balance_before, balance_after)
- НИКОГДА не обновляйте balance_kopecks напрямую, только через методы *_with_transaction

### Services Pattern

Бизнес-логика в сервисах (`app/services/`):
- `JsonWebToken` - JWT энкодинг/декодинг
- `CloudPaymentsService` - интеграция платежей (планируется)

**Mailers** (Action Mailer + Solid Queue):
- `OrderRequestMailer` - уведомления о заявках
- `UserMailer` - 5 типов писем:
  - `welcome_email` - при регистрации
  - `order_confirmation` - при создании заказа
  - `payment_received` - при успешной оплате
  - `product_access_granted` - при выдаче доступа
  - `password_reset` - при восстановлении пароля

### Testing Strategy

**RSpec с FactoryBot (155+ тестов, 100% pass rate):**
- Model specs: валидации, ассоциации, scopes, методы (131 тест, 100% coverage)
- Request specs: интеграционные тесты контроллеров (76+ тестов):
  - Dashboard specs (17 tests)
  - Admin specs (27 tests: products, orders, dashboard)
  - CloudPayments webhook specs (12 tests, HMAC verification)
  - Mailer specs (20 tests, all 5 email types)
- Factories: `spec/factories/*` для всех моделей
- Helpers: `spec/support/auth_helpers.rb` (sign_in, api_sign_in, generate_cloudpayments_signature)

**Test Coverage Goals:**
- ✅ Models: 100%
- ✅ Request specs: 85%+
- ✅ Mailers: 90%+

**См. `TESTING_GUIDE.md` для подробностей**

### Performance Optimization

**Tools:**
- Bullet - N+1 query detection
- Rack Mini Profiler - request profiling

**Implemented:**
- ✅ Eager loading: `Product.includes(:category)`, `Order.includes(:user, :order_items)`
- ✅ Fragment caching: products index, dashboard courses
- ✅ Database indexes: 100% coverage (все foreign keys indexed)
- ✅ Query optimization: pluck, exists?, find_each

**Результаты:**
- GET /products: -88% queries (25 → 3)
- GET /dashboard: -82% queries (40 → 7)
- GET /admin: -40% queries (5 → 3)

**См. `PERFORMANCE_GUIDE.md` для подробностей**

## Rails 8 Documentation

Comprehensive Rails 8 documentation in Russian: `AIDocs/Rails/` (20 files)

**Key references:**
- `01-ruby-basics.md` - 2 spaces, snake_case, frozen_string_literal
- `11-rails-models.md` - Active Record patterns, N+1 prevention
- `12-rails-controllers.md` - Strong Parameters, RESTful patterns
- `17-rails-security.md` - SQL injection, XSS, CSRF protection
- `20-rails-turbo-stimulus.md` - Turbo Frames/Streams, Stimulus controllers

## Frontend Design System

**Концепция**: "Spiritual Minimalism meets Modern Technology"

### Уникальные особенности:
- **Glassmorphism** с backdrop-filter для карточек
- **Плавные анимации**: fadeIn, pulse, shimmer
- **Градиентная палитра**: индиго (var(--primary)) → аметист → золото (var(--accent))
- **Русская типографика**: IBM Plex Sans (основной) + IBM Plex Serif (заголовки)
- **Responsive breakpoints**: mobile (до 640px), tablet (641-1024px), desktop (1025px+)

### Основные CSS переменные:
```css
--primary: #4F46E5    /* Индиго */
--secondary: #9333EA  /* Аметист */
--accent: #F59E0B     /* Золото */
--background: #0F172A /* Темный фон */
--surface: #1E293B    /* Поверхность */
--text: #F8FAFC       /* Светлый текст */
```

**См. `AIDocs/FRONTEND.md` и `app/assets/stylesheets/application.css`**

## Development Guidelines

**Critical Rules:**
1. **Money in kopecks** - ALL monetary values as `integer` (kopecks), NEVER decimals
2. **Enum prefixes** - `classification_admin?`, NOT `admin?` | `status_published?` NOT `published?`
3. **Russian language** - User-facing content, error messages, flash notices in Russian
4. **Rails 8 defaults** - Solid Queue/Cache/Cable, Propshaft, Import Maps
5. **Security** - Параметризованные запросы, экранирование вывода, Strong Parameters
6. **Testing** - RSpec model + request specs for all features (155+ tests)
7. **Performance** - `includes` to prevent N+1, pagination always, fragment caching
8. **Frontend** - Turbo Frames/Streams first, minimal Stimulus JS, Design System CSS vars

## Code Style

- **RuboCop**: `bundle exec rubocop` (omakase style) | Auto-fix: `rubocop -a`
- **Security**: `bundle exec brakeman` (static analysis)
- **Format**: 2 spaces, 80-100 chars/line, `# frozen_string_literal: true`
- **Naming**: snake_case (methods/vars), CamelCase (classes), SCREAMING_SNAKE_CASE (constants)
- **Migrations**: NEVER edit schema.rb manually, always use migrations
- **Timestamps**: Always `t.timestamps` in migrations

## Demo Data

После `rails db:seed` доступны тестовые аккаунты:

| Email | Пароль | Classification | Баланс кошелька |
|-------|--------|----------------|-----------------|
| admin@bronnikov.com | password123 | admin | 10,000 ₽ |
| director@bronnikov.com | password123 | center_director | 5,000 ₽ |
| specialist@bronnikov.com | password123 | specialist | 3,000 ₽ |
| client@example.com | password123 | client | 1,000 ₽ |
| guest@example.com | password123 | guest | 0 ₽ |

**Продукты**: 7 демо-продуктов в 4 категориях (Видеокурсы, Книги, Курсы, Мероприятия)

## Project Status

**Завершено (Production-Ready):**
- ✅ Phase 0: Rails 8 инфраструктура
- ✅ Phase 1: JWT Authentication + User система (14 типов classification)
- ✅ Phase 3: Витрина магазина (Product, Category, Order)
- ✅ Phase A: Dashboard (8 sections) + Password Reset
- ✅ Phase B: Admin Panel Enhancement (bulk actions, analytics, revenue charts)
- ✅ Phase C: Critical Integrations (CloudPayments HMAC, Email, GA4)
- ✅ Phase D1-D2: Система заявок (OrderRequest с AASM, auto-approval flow)
- ✅ Phase E: Testing (155+ tests) + Performance (N+1 elimination, caching)
- ✅ Phase E2: Внутренний кошелек (Wallet, WalletTransaction с audit trail)
- ✅ Frontend: 8 dashboard views + Glassmorphism Design System
- ✅ Telegram бот: базовая интеграция (webhook, команды)
- ✅ External Forms: WordPress интеграция для создания заявок

**В планах (Optional):**
- Phase 2: Бизнес-аккаунт (маркетплейс центров с геолокацией)
- Phase 4: Календарь/Афиша событий (бронирование + оплата)
- Phase 7: WordPress SSO плагин (validate_token endpoint готов)

**См. `PROJECT_STATUS.md` и `AIDocs/Roadmap.md` для подробностей**

## Important Implementation Details

### Enum Prefixes (КРИТИЧНО!)
- **User classification**: используйте `classification_` префикс
  - ✅ `user.classification_admin?`
  - ❌ `user.admin?` (не существует)
- **Product status**: используйте `status_` префикс
  - ✅ `product.status_published?`
- **Order status**: используйте `status_` префикс
  - ✅ `order.status_paid?`

### Auto-created Associations
- При создании `User` автоматически создаются:
  - `Profile` (пустой)
  - `Wallet` (balance_kopecks = 0)
  - `Rating` (points = 0, level = 1)
- Не нужно создавать вручную в контроллерах

### AASM State Machines - Critical Callbacks Timing

**ВАЖНО:** AASM after callbacks выполняются ДО сохранения изменений в БД!

**Проблема:**
```ruby
# ❌ НЕ РАБОТАЕТ - статус еще не изменен в БД
event :approve do
  transitions from: :pending, to: :approved, after: :do_something
end

def do_something
  pay! if may_pay?  # FAIL! Статус в памяти = approved, но в БД = pending
end
```

**Решение - использовать after_commit:**
```ruby
# ✅ РАБОТАЕТ
after_commit :do_something_after_approve, if: :saved_change_to_approved?

def saved_change_to_approved?
  saved_change_to_status? && status == 'approved'
end

def do_something_after_approve
  pay! if may_pay?  # OK! Статус уже в БД
end
```

**Примеры в кодовой базе:**
- `OrderRequest#process_auto_payment` - вызывается через `after_commit`, не через AASM after
- `OrderRequest#auto_complete` - вызывается через `after_save` с флагом `@should_auto_complete`

### Session vs API Authentication
- **Web интерфейс**: JWT хранится в `cookies.encrypted[:jwt_token]`
- **API**: JWT передается в `Authorization: Bearer <token>` header
- `ApplicationController` поддерживает оба метода автоматически

### CloudPayments HMAC Verification (SECURITY CRITICAL!)

**ВАЖНО:** Все CloudPayments webhooks проверяются через HMAC-SHA256 signature:
```ruby
# app/controllers/webhooks/cloud_payments_controller.rb
def verify_signature
  signature = request.headers['Content-HMAC']
  body = request.raw_post
  expected = OpenSSL::HMAC.hexdigest('SHA256', api_secret, body)

  signature == expected
end
```

**Тестирование:**
```ruby
# spec/support/auth_helpers.rb
signature = generate_cloudpayments_signature(order)
webhook_params[:Signature] = signature
post webhooks_cloudpayments_pay_path, params: webhook_params
```

## Configuration Files

### Credentials (for production)
```bash
rails credentials:edit --environment production
```

**Required credentials:**
```yaml
cloudpayments:
  public_id: YOUR_PUBLIC_ID
  api_secret: YOUR_API_SECRET

google_analytics:
  measurement_id: G-XXXXXXXXXX

smtp:
  username: YOUR_SMTP_USERNAME
  password: YOUR_SMTP_PASSWORD
```

### Environment Variables
```bash
APP_HOST=https://platform.bronnikov.com
DATABASE_URL=postgresql://...
SECRET_KEY_BASE=...
RAILS_ENV=production
```

**См. `EMAIL_SETUP.md` и `GOOGLE_ANALYTICS_SETUP.md` для configuration guides**

## Additional Documentation

**Comprehensive guides созданы:**
- `TESTING_GUIDE.md` (460+ строк) - Test stack, helpers, 155+ tests
- `PERFORMANCE_GUIDE.md` (500+ строк) - Bullet, indexes, caching, optimization
- `EMAIL_SETUP.md` (200+ строк) - SMTP, Letter Opener, testing
- `GOOGLE_ANALYTICS_SETUP.md` (400+ строк) - GA4, e-commerce tracking, privacy
- `PROJECT_STATUS.md` (470+ строк) - Status, roadmap, deployment checklist
- `AIDocs/FRONTEND.md` - Design System documentation
- `AIDocs/API.md` - REST API documentation
- `WORDPRESS_SSO_GUIDE.md` - WordPress SSO plugin guide (для будущей реализации)
- `TELEGRAM_BOT_GUIDE.md` - Telegram bot integration guide
- `DEPLOY.md` - Production deployment instructions

## Notes

- Platform serves Russian-speaking audience
- Compliance with Russian data protection laws (152-ФЗ) is mandatory
- High emphasis on modern design with glassmorphism effects
- All monetary operations in RUB (копейки for precision)
- JWT токены expire через 24 часа (настраивается в JsonWebToken)
- Password reset tokens expire через 24 часа
- Rails 8 defaults: Solid Queue, Solid Cache, Solid Cable, Propshaft
- Production-ready: 155+ tests (100% pass), 0 security issues, optimized performance
