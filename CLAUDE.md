# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Платформа «Система Бронникова»** - информационная платформа с личным кабинетом и единой авторизацией для всех сервисов и сайтов системы Бронников-Феклерон.

Это образовательная экосистема для клиентов, учеников, специалистов и руководителей центров и клубов системы "Бронников-Феклерон".

**Статус:** MVP завершен и работает. 302 теста (207 проходят, 95 падают из-за отсутствующих фабрик).

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

## Common Development Commands

### Server Management
```bash
# Запуск сервера (по умолчанию http://localhost:3000)
rails server
# или короткая форма
rails s

# Остановка: Ctrl+C или kill <PID>
ps aux | grep puma  # найти PID процесса
kill <PID>
```

### Database
```bash
# Создание БД
rails db:create

# Запуск миграций
rails db:migrate

# Откат последней миграции
rails db:rollback

# Заполнение демо-данными (5 пользователей, 7 продуктов, 4 категории)
rails db:seed

# Полный сброс БД
rails db:reset  # drop + create + migrate + seed

# Консоль БД
rails db

# Rails консоль
rails console
# или
rails c
```

### Testing
```bash
# Все тесты (302 теста)
bundle exec rspec

# С подробным выводом
bundle exec rspec --format documentation

# Конкретный файл
bundle exec rspec spec/models/user_spec.rb

# Конкретный тест по строке
bundle exec rspec spec/models/user_spec.rb:15

# Только тесты моделей (131 тест, 98% pass rate)
bundle exec rspec spec/models/

# С покрытием кода
COVERAGE=true bundle exec rspec
```

### Code Quality
```bash
# Проверка стиля кода (RuboCop)
bundle exec rubocop

# Автоисправление
bundle exec rubocop -a

# Проверка безопасности (Brakeman)
bundle exec brakeman

# Проверка уязвимостей в зависимостях
bundle exec bundler-audit
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
- Декодинг: `JsonWebToken.decode(token)` - возвращает HashWithIndifferentAccess или nil (при ошибке/истечении)
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
├── application_controller.rb       # Базовый контроллер (JWT + cookies auth)
├── home_controller.rb              # Главная страница
├── sessions_controller.rb          # Вход/выход (web) - создает JWT в cookies
├── registrations_controller.rb     # Регистрация (web)
├── password_resets_controller.rb   # Восстановление пароля
├── dashboard_controller.rb         # Личный кабинет (8 экшенов)
├── categories_controller.rb        # Список категорий
├── products_controller.rb          # Каталог и детали продуктов
├── orders_controller.rb            # Заказы и оплата
├── order_payments_controller.rb    # Обработка платежей
├── order_requests_controller.rb    # Заявки на покупку (создание, оплата)
├── external_forms_controller.rb    # Внешние формы для WordPress интеграции
├── telegram_controller.rb          # Telegram бот интеграция
├── admin/                          # Admin namespace
│   ├── dashboard_controller.rb
│   ├── products_controller.rb
│   ├── users_controller.rb
│   └── interaction_histories_controller.rb
├── webhooks/
│   ├── cloud_payments_controller.rb # Webhooks от CloudPayments
│   └── telegram_controller.rb       # Telegram webhooks
└── api/
    └── v1/
        ├── base_controller.rb      # Базовый для API
        ├── authentication_controller.rb  # JWT login/logout/validate
        └── users_controller.rb     # User API
```

### Routes Architecture

**Web Routes**:
- Root: `/` → `home#index`
- Auth: `/login`, `/register`, `/forgot-password`
- Shop: `/categories`, `/products`, `/cart`, `/orders`
- Dashboard: `/dashboard/*` (8 разделов)

**API Routes** (все под `/api/v1/`):
- POST `/api/v1/login` - JWT аутентификация (возвращает token)
- DELETE `/api/v1/logout` - Выход (инвалидация токена)
- GET `/api/v1/validate_token` - Валидация JWT (для WordPress SSO)
- GET/PATCH `/api/v1/users/:id` - User API (требует JWT)

**Admin Routes** (все под `/admin/`, требуют `admin_role?`):
- GET `/admin` - Admin dashboard
- CRUD `/admin/products` - Управление продуктами
- GET/PATCH `/admin/users` - Управление пользователями
- CRUD `/admin/interaction_histories` - История взаимодействий

**Webhooks**:
- POST `/webhooks/cloudpayments/pay` - Успешная оплата
- POST `/webhooks/cloudpayments/fail` - Неудачная оплата
- POST `/webhooks/cloudpayments/refund` - Возврат средств

### Money Handling

**Важно:** Все цены хранятся в копейках (integer) для точности:
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

Бизнес-логика вынесена в сервисы (`app/services/`):
- `JsonWebToken` - JWT энкодинг/декодинг:
  - `encode(payload, exp = 24.hours)` - создание токена
  - `decode(token)` - декодирование (возвращает Hash или nil)
  - Использует `Rails.application.credentials.dig(:secret_key_base)`
- `CloudPaymentsService` - интеграция платежей (планируется)

**Паттерн сервисов**:
- Один сервис = одна ответственность
- Class methods для stateless операций
- Instance methods для stateful операций

**Важно про Mailers:**
- `OrderRequestMailer` - уведомления о заявках (одобрение, отклонение, недостаточно средств)
- `UserMailer` - email подтверждения, сброс пароля, заказы
- Все mailers используют Action Mailer + `deliver_later` для фоновой отправки

### Testing Strategy

**RSpec с FactoryBot**:
- Model specs: валидации, ассоциации, scopes, методы
- Request specs: интеграционные тесты контроллеров
- Factories: `spec/factories/*` для всех моделей
- Helpers: shoulda-matchers, database_cleaner

**Текущий статус тестов:**
- ✅ 207/302 тестов проходят (68%)
- ✅ 128/131 model specs проходят (98%)
- ⚠️ 95 request specs падают из-за отсутствующих фабрик:
  - `order_item` - нужна фабрика (29 тестов)
  - `product_access` - нужна фабрика (7 тестов)
  - `:draft` trait в Product - нужен trait (6 тестов)

**Важные factories:**
- `spec/factories/users.rb` - User с traits по classification
- `spec/factories/products.rb` - Product с типами и статусами
- `spec/factories/orders.rb` - Order с разными статусами
- `spec/factories/wallets.rb` - Wallet с балансом (traits: `:empty`, `:wealthy`)
- `spec/factories/wallet_transactions.rb` - Транзакции с типами
- `spec/factories/order_requests.rb` - Заявки с AASM states

## Rails Documentation

Comprehensive Rails 8 documentation in Russian: `AIDocs/Rails/` (20 files)

**Key references:**
- `01-ruby-basics.md` - 2 spaces, snake_case, frozen_string_literal
- `11-rails-models.md` - Active Record patterns, N+1 prevention
- `12-rails-controllers.md` - Strong Parameters, RESTful patterns
- `17-rails-security.md` - SQL injection, XSS, CSRF protection
- `20-rails-turbo-stimulus.md` - Turbo Frames/Streams, Stimulus controllers

## Key Architecture Requirements

From the project specification:

### User Roles & Classification
- Guests → Clients → Club Members → Representatives → Instructors → Specialists → Center Directors → Platform Admins

### Core Platform Features
1. **Единая авторизация (SSO)** - Single sign-on across all ecosystem services
2. **Личный кабинет** - User dashboard with profile, wallet, rating system
3. **Бизнес-аккаунт** - B2B space for partners and centers
4. **Маркетплейс** - Marketplace for centers and representatives with geolocation
5. **Витрина магазина** - Product/service storefront
6. **Календарь/Афиша** - Events calendar with booking and payment
7. **Внутренний счет (кошелек)** - User wallet for platform purchases
8. **Рейтинговая система** - User rating and bonus points system

### Integration Requirements
- WordPress sites integration (передача сессии авторизованного пользователя)
- CRM system integration
- Google Analytics
- Bizon365 (webinar system)
- Social networks (VK, FB, Twitter) sharing
- Payment processing

### Technical Requirements
- Mobile-responsive design
- Search functionality across all content
- Comment and discussion system
- Email notifications/newsletters management
- Content moderation (automated + manual)
- User privacy controls (152-ФЗ compliance)
- GDPR/Cookie consent

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

**Подробнее**: См. `FRONTEND.md` и `app/assets/stylesheets/application.css`

## Common Development Patterns

### Adding New Product Type
1. Add to enum: `Product` → `enum :product_type`
2. Create migration if additional fields needed
3. Update factory: `spec/factories/products.rb`
4. Update tests: `spec/models/product_spec.rb`

### Creating API Endpoint
1. Add route: `config/routes.rb` → `namespace :api, :v1`
2. Create controller inheriting from `Api::V1::BaseController`
3. Return JSON with proper status code
4. Write request spec: `spec/requests/api/v1/`

### Order Request Flow (with auto-approval)
```
1. User создает OrderRequest через форму/API
2. OrderRequest.create → before_create callbacks:
   - generate_request_number (REQ-timestamp-HEX)
   - set_total_from_product (копирует price_kopecks)
3. Статус: pending
4. Если product.auto_approve = true:
   - approve! → статус: approved
   - after_commit → process_auto_payment:
     - Wallet.withdraw_with_transaction (создает WalletTransaction)
     - pay! → статус: paid
     - after callback → create_order_and_grant_access:
       - Создает Order (status: paid)
       - Создает OrderItem
       - Создает ProductAccess
     - after_save → auto_complete → статус: completed
5. Если product.auto_approve = false или недостаточно средств:
   - Админ одобряет вручную через /admin/order_requests
   - Пользователь платит через /order_requests/:id/pay
```

### Payment Flow (CloudPayments)
Order → OrderPaymentsController → CloudPayments → Webhook → ProductAccess created + Order.status → paid

## Development Guidelines

**Critical Rules:**
1. **Money in kopecks** - ALL monetary values as `integer` (kopecks), NEVER decimals
2. **Enum prefixes** - `classification_admin?`, NOT `admin?` | `status_published?` NOT `published?`
3. **Russian language** - User-facing content, error messages, flash notices in Russian
4. **Rails 8 defaults** - Solid Queue/Cache/Cable, Propshaft, Import Maps
5. **Security** - Параметризованные запросы, экранирование вывода, Strong Parameters
6. **Testing** - RSpec model + request specs for all features (currently 51 tests)
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

## Project Status & Roadmap

**Завершено (MVP)**:
- ✅ Phase 0: Rails 8 инфраструктура
- ✅ Phase 1: JWT Authentication + User система (14 типов classification)
- ✅ Phase 3: Витрина магазина (Product, Category, Order)
- ✅ Phase D1-D2: Система заявок (OrderRequest с AASM, auto-approval flow)
- ✅ Phase E2: Внутренний кошелек (Wallet, WalletTransaction с audit trail)
- ✅ Frontend: Главная, Каталог, Детали продукта (Glassmorphism Design System)
- ✅ Telegram бот: базовая интеграция (webhook, команды)
- ✅ External Forms: WordPress интеграция для создания заявок
- ✅ Тесты: 302 RSpec теста (207 проходят, 95 требуют фабрик)

**В планах** (см. `Roadmap.md`):
- Phase 2: Бизнес-аккаунт (маркетплейс центров с геолокацией)
- Phase 4: Календарь/Афиша событий (бронирование + оплата)
- Phase 7: WordPress SSO плагин (validate_token endpoint готов)
- Frontend: Личный кабинет улучшения, Admin панель UX
- Testing: Создать недостающие фабрики (order_item, product_access)

## Important Implementation Details

### Money Handling (КРИТИЧНО!)
- **Всегда используйте копейки**: все денежные суммы хранятся как `integer` в копейках
- **Преобразование**: `Money.new(kopecks, 'RUB')` через money-rails gem
- **В views**: `humanized_money_with_symbol(@product.price)`
- **Примеры**: 1000 копеек = 10.00 рублей
- **Поля**: `price_kopecks`, `total_kopecks`, `balance_kopecks`

### Enum Prefixes
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

## Notes

- Platform serves Russian-speaking audience
- Compliance with Russian data protection laws (152-ФЗ) is mandatory
- High emphasis on modern design with glassmorphism effects
- All monetary operations in RUB (копейки for precision)
- JWT токены expire через 24 часа (настраивается в JsonWebToken)
- Rails 8 defaults: Solid Queue, Solid Cache, Solid Cable, Propshaft
