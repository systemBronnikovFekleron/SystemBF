# Документация системы подролей (SubRole)

## Обзор

Система подролей - это расширенная система контроля доступа для платформы «Система Бронникова», позволяющая гранулированно управлять доступом пользователей к контенту (Product, Article, Event, WikiPage).

**Дата реализации:** 2026-02-05
**Версия:** 1.0.0
**Статус:** Production-ready ✅

---

## Ключевые особенности

### 1. 14 системных ролей
Автоматически созданы при миграции:
- `guest` (0) - Гость
- `client` (1) - Клиент
- `club_member` (2) - Участник клуба
- `representative` (3) - Представитель
- `trainee` (4) - Стажер
- `instructor_1` (5) - Инструктор 1 кат.
- `instructor_2` (6) - Инструктор 2 кат.
- `instructor_3` (7) - Инструктор 3 кат.
- `specialist` (8) - Специалист
- `expert` (9) - Эксперт-Диагност
- `center_director` (10) - Директор Центра
- `curator` (11) - Куратор
- `manager` (12) - Менеджер платформы
- `admin` (13) - Администратор

### 2. OR логика доступа
Если у контента роли `[instructor_1, specialist]`, а у пользователя `[instructor_1]` - **доступ ЕСТЬ**.

### 3. Публичный vs Приватный контент
- **Публичный**: контент без ролей доступен всем
- **Приватный**: контент с ролями доступен только пользователям с этими ролями

### 4. Auto-assignment ролей
Роли выдаются автоматически:
- При покупке продукта (через `product.auto_grant_sub_roles`)
- При завершении инициации (через `initiation.auto_grant_sub_roles`)

### 5. Audit trail
Все назначения ролей записываются с:
- `granted_by` - кто назначил
- `granted_via` - способ назначения (manual, product_purchase, initiation_completed)
- `source` - источник (Product, Initiation)
- `granted_at` - дата назначения
- `expires_at` - дата истечения (опционально)

---

## Структура базы данных

### Таблица `sub_roles`
```ruby
create_table :sub_roles do |t|
  t.string :name, null: false           # Уникальное название (snake_case)
  t.string :display_name, null: false   # Отображаемое имя
  t.text :description                   # Описание роли
  t.integer :level, default: 0          # Уровень роли (0-13 системные, 50+ кастомные)
  t.boolean :system_role, default: false # Флаг системной роли
  t.timestamps
end

add_index :sub_roles, :name, unique: true
add_index :sub_roles, :system_role
add_index :sub_roles, :level
```

### Таблица `user_sub_roles`
```ruby
create_table :user_sub_roles do |t|
  t.references :user, null: false, foreign_key: true
  t.references :sub_role, null: false, foreign_key: true
  t.bigint :granted_by_id                # User который назначил роль
  t.string :granted_via                  # manual, product_purchase, initiation_completed
  t.bigint :source_id                    # ID источника (Product, Initiation)
  t.string :source_type                  # Тип источника (полиморфная связь)
  t.datetime :granted_at, null: false    # Дата назначения
  t.datetime :expires_at                 # Дата истечения (опционально)
  t.timestamps
end

add_index :user_sub_roles, [:user_id, :sub_role_id], unique: true
```

### Таблица `content_sub_roles`
```ruby
create_table :content_sub_roles do |t|
  t.references :sub_role, null: false, foreign_key: true
  t.references :content, polymorphic: true, null: false # Product, Article, Event, WikiPage
  t.timestamps
end

add_index :content_sub_roles, [:content_type, :content_id, :sub_role_id], unique: true
```

### Поля в таблицах `products` и `initiations`
```ruby
add_column :products, :auto_grant_sub_roles, :jsonb, default: []
add_column :initiations, :auto_grant_sub_roles, :jsonb, default: []
```

---

## API моделей

### SubRole

**Методы:**
```ruby
SubRole.ordered           # Сортировка по level, name
SubRole.system_roles      # Только системные роли
SubRole.custom_roles      # Только кастомные роли

sub_role.users_count      # Количество пользователей (с кешированием)
sub_role.content_count    # Количество контента (с кешированием)
```

### User

**Методы:**
```ruby
# Назначение ролей
user.grant_sub_role!(role_id_or_name, granted_by: nil, granted_via: 'manual', source: nil)
user.grant_sub_roles!([role_ids_or_names], granted_by: nil, granted_via: 'manual', source: nil)

# Проверка ролей
user.has_sub_role?(role_id_or_name)          # Проверка одной роли
user.has_any_sub_role?([role_ids_or_names])  # Проверка наличия хотя бы одной роли

# Получение ролей
user.sub_roles                               # Все роли пользователя
user.active_sub_roles                        # Только активные (не истекшие)
```

**Примеры:**
```ruby
# Назначить роль вручную
user.grant_sub_role!('client', granted_by: admin, granted_via: 'manual')

# Назначить несколько ролей
user.grant_sub_roles!(['client', 'club_member'])

# Проверить роль
user.has_sub_role?('client')  # => true

# Проверить наличие хотя бы одной роли
user.has_any_sub_role?(['instructor_1', 'specialist'])  # => true если есть хотя бы одна
```

### Product, Article, Event, WikiPage (SubRoleRestrictable)

**Scopes:**
```ruby
Product.accessible_by(user)   # Фильтрация по доступу (публичный + приватный с ролями)
Product.public_content        # Только публичный контент (без ролей)
Product.private_content       # Только приватный контент (с ролями)
```

**Методы:**
```ruby
# Проверка доступа
product.accessible_by?(user)     # Может ли пользователь получить доступ
product.is_public?               # Публичный ли контент
product.is_private?              # Приватный ли контент

# Управление ролями
product.add_required_roles([role_ids_or_names])  # Добавить требуемые роли
product.required_sub_roles                       # Требуемые роли (relation)
product.required_sub_role_ids                    # ID требуемых ролей
product.required_sub_role_names                  # Имена требуемых ролей
```

**Примеры:**
```ruby
# Сделать продукт приватным для клиентов
product.add_required_roles(['client'])

# Проверить доступ
product.accessible_by?(user)  # => true если у user есть роль 'client'

# Получить все доступные продукты
Product.accessible_by(current_user)
```

### OrderRequest (Auto-grant flow)

**Поток auto-assignment при покупке:**
```ruby
# 1. Создание заявки
order_request = OrderRequest.create!(user: user, product: product)

# 2. Одобрение (если auto_approve = true)
order_request.approve!

# 3. Auto-payment (списание с кошелька)
# → wallet.withdraw_with_transaction(total_kopecks, order_request)

# 4. Переход в статус paid
order_request.pay!

# 5. Создание Order, OrderItem, ProductAccess
# → create_order_and_grant_access

# 6. Auto-grant sub_roles (если настроено)
if product.auto_grant_sub_roles.present?
  user.grant_sub_roles!(
    product.auto_grant_sub_roles,
    granted_via: 'product_purchase',
    source: product
  )
end

# 7. Auto-complete
# → complete!
```

### Initiation (Auto-grant flow)

**Поток auto-assignment при завершении:**
```ruby
# 1. Создание инициации
initiation = Initiation.create!(
  user: user,
  conducted_by: instructor,
  auto_grant_sub_roles: [SubRole.find_by(name: 'instructor_1').id]
)

# 2. Завершение инициации
initiation.update!(status: :completed)

# 3. Auto-grant sub_roles (через after_commit callback)
user.grant_sub_roles!(
  initiation.auto_grant_sub_roles,
  granted_by: conducted_by,
  granted_via: 'initiation_completed',
  source: initiation
)
```

---

## Контроллеры

### Admin::SubRolesController
```ruby
GET    /admin/sub_roles          # index   - Список ролей
POST   /admin/sub_roles          # create  - Создание кастомной роли
GET    /admin/sub_roles/new      # new     - Форма создания
GET    /admin/sub_roles/:id      # show    - Детали роли
GET    /admin/sub_roles/:id/edit # edit    - Форма редактирования (только кастомные)
PATCH  /admin/sub_roles/:id      # update  - Обновление (только кастомные)
DELETE /admin/sub_roles/:id      # destroy - Удаление (только кастомные без пользователей)
```

**Ограничения:**
- Системные роли нельзя редактировать или удалять
- Роли с назначенными пользователями нельзя удалять

### Admin::UserSubRolesController
```ruby
GET    /admin/users/:user_id/sub_roles     # index   - Список ролей пользователя + форма назначения
POST   /admin/users/:user_id/sub_roles     # create  - Назначить роль пользователю
DELETE /admin/users/:user_id/sub_roles/:id # destroy - Отозвать роль
```

### Admin::ProductsController (новые методы)
```ruby
GET    /admin/products/:id/edit_sub_roles   # edit_sub_roles   - Настройка доступа
PATCH  /admin/products/:id/update_sub_roles # update_sub_roles - Сохранение настроек
```

**Параметры update_sub_roles:**
- `sub_role_ids[]` - Роли для доступа к продукту
- `auto_grant_sub_role_ids[]` - Роли для авто-выдачи после покупки

### Обновленные контроллеры с фильтрацией

**ProductsController:**
```ruby
def index
  @products = Product.published.accessible_by(current_user).ordered
end

def show
  @product = Product.friendly.find(params[:id])
  redirect_to products_path, alert: 'Нет доступа' unless @product.accessible_by?(current_user)
end
```

**DashboardController:**
```ruby
def news
  @news = Article.published.accessible_by(current_user).article_type_news.ordered
end

def wiki_show
  @page = WikiPage.friendly.find(params[:slug])
  redirect_to dashboard_wiki_path, alert: 'Нет доступа' unless @page.accessible_by?(current_user)
end
```

**EventsController:**
```ruby
def index
  @events = Event.status_published.accessible_by(current_user).upcoming.ordered
end
```

---

## Views

### Админ-панель

**Список ролей** (`/admin/sub_roles`):
- Таблица со всеми ролями
- Статистика (всего, системных, кастомных)
- Кнопка создания новой роли
- Действия: показать, изменить (только кастомные), удалить (только кастомные)

**Детали роли** (`/admin/sub_roles/:id`):
- Основная информация (name, display_name, description, level)
- Статистика (количество пользователей, количество контента)
- Предупреждение для системных ролей

**Создание/редактирование роли**:
- Форма с полями: name, display_name, description, level
- Валидация и вывод ошибок
- Только для кастомных ролей

**Управление ролями пользователя** (`/admin/users/:id/sub_roles`):
- Таблица активных ролей с информацией о назначении
- Форма быстрого назначения новой роли
- Список доступных ролей с группировкой (системные/кастомные)
- Кнопка отзыва роли

**Настройка доступа продукта** (`/admin/products/:id/edit_sub_roles`):
- Выбор требуемых ролей для доступа (чекбоксы)
- Выбор ролей для авто-выдачи (чекбоксы)
- Текущее состояние (публичный/приватный)
- Примеры использования
- Предупреждения

### Сайдбар админки

Добавлена ссылка в секцию "ПОЛЬЗОВАТЕЛИ":
```erb
<%= link_to admin_sub_roles_path do %>
  <svg>...</svg>
  Подроли
<% end %>
```

Активна когда: `controller_name == 'sub_roles' || controller_name == 'user_sub_roles'`

### Кнопки навигации

**В `admin/products/show.html.erb`:**
- Кнопка "Настроить доступ" → `edit_sub_roles_admin_product_path`

**В `admin/users/show.html.erb`:**
- Кнопка "Управление подролями" → `admin_user_sub_roles_path`

---

## Примеры использования

### Пример 1: Бесплатный вводный курс
```ruby
product = Product.create!(name: 'Вводный курс', price_kopecks: 0, status: :published)
# Требуемые роли: не выбрано
# Авто-выдача: не выбрано
# Результат: доступен всем, роли не выдаются
```

### Пример 2: Платный курс для клиентов
```ruby
product = Product.create!(
  name: 'Базовый курс',
  price_kopecks: 50000,
  status: :published,
  auto_grant_sub_roles: [SubRole.find_by(name: 'client').id]
)
# Требуемые роли: не выбрано
# Авто-выдача: client
# Результат: после покупки выдается роль "Клиент"
```

### Пример 3: Продвинутый курс для специалистов
```ruby
product = Product.create!(name: 'Продвинутый курс', price_kopecks: 150000, status: :published)
instructor_role = SubRole.find_by(name: 'instructor_1')
specialist_role = SubRole.find_by(name: 'specialist')
product.add_required_roles([instructor_role.id, specialist_role.id])
# Требуемые роли: instructor_1, specialist
# Результат: доступен только инструкторам и специалистам
```

### Пример 4: VIP контент с авто-выдачей
```ruby
premium_role = SubRole.create!(
  name: 'premium_member',
  display_name: 'Премиум участник',
  level: 50
)

product = Product.create!(
  name: 'VIP курс',
  price_kopecks: 300000,
  status: :published,
  auto_grant_sub_roles: [premium_role.id]
)
product.add_required_roles([premium_role.id])
# Требуемые роли: premium_member
# Авто-выдача: premium_member
# Результат: после покупки пользователь получает роль и доступ к VIP контенту
```

### Пример 5: Инициация с автоматической выдачей роли
```ruby
user = User.find(1)
instructor = User.find_by(classification: :instructor_1)
instructor_role = SubRole.find_by(name: 'instructor_1')

initiation = Initiation.create!(
  user: user,
  conducted_by: instructor,
  initiation_type: 'first',
  level: 1,
  status: :pending,
  auto_grant_sub_roles: [instructor_role.id]
)

# При завершении инициации роль автоматически назначается
initiation.update!(status: :completed)
user.reload.has_sub_role?('instructor_1')  # => true
```

---

## Тестирование

### Результаты тестов
```
31 examples, 0 failures

SubRole model specs:        11 tests ✅
UserSubRole model specs:    12 tests ✅
Integration specs:           8 tests ✅
```

### Ключевые тесты

**Model specs:**
- Валидации и ассоциации
- Scopes (system_roles, custom_roles, ordered)
- Методы (users_count, content_count)
- Callbacks (set_granted_at, active scopes)

**Integration specs:**
- Auto-grant при покупке продукта
- Auto-grant при завершении инициации
- Audit trail (source, granted_by, granted_via)
- Проверка что роли не выдаются при failed инициации

**Запуск тестов:**
```bash
# Все SubRole тесты
bundle exec rspec spec/models/sub_role_spec.rb spec/models/user_sub_role_spec.rb spec/integration/order_request_sub_role_assignment_spec.rb

# С подробным выводом
bundle exec rspec --format documentation
```

---

## Безопасность

### Policy (Pundit)
```ruby
class SubRolePolicy < ApplicationPolicy
  def index?
    user&.admin_role?  # Только admin, manager, curator
  end

  def create?
    user&.admin_role?
  end

  def update?
    user&.admin_role? && !record.system_role?  # Системные роли нельзя редактировать
  end

  def destroy?
    user&.admin_role? && !record.system_role? && record.users.none?  # Только пустые кастомные роли
  end
end
```

### Ограничения
- Системные роли защищены от редактирования и удаления
- Роли с назначенными пользователями нельзя удалять
- Только admin_role может управлять ролями
- Audit trail для всех назначений

---

## Performance

### Кеширование
```ruby
# SubRole#users_count
Rails.cache.fetch("sub_role_#{id}_users_count", expires_in: 1.hour) { users.count }

# SubRole#content_count
Rails.cache.fetch("sub_role_#{id}_content_count", expires_in: 1.hour) { content_sub_roles.count }
```

### Индексы
```ruby
# sub_roles
add_index :sub_roles, :name, unique: true
add_index :sub_roles, :system_role
add_index :sub_roles, :level

# user_sub_roles
add_index :user_sub_roles, [:user_id, :sub_role_id], unique: true
add_index :user_sub_roles, :granted_by_id
add_index :user_sub_roles, [:source_type, :source_id]
add_index :user_sub_roles, :expires_at

# content_sub_roles
add_index :content_sub_roles, [:content_type, :content_id, :sub_role_id], unique: true
```

### Eager loading
```ruby
# В контроллерах
@active_roles = @user.user_sub_roles.active.includes(:sub_role, :granted_by).ordered
@products = Product.published.accessible_by(current_user).includes(:category).ordered
```

---

## Миграция существующих данных

Если у вас уже есть пользователи и вы хотите назначить им роли:

```ruby
# Назначить всем клиентам роль 'client'
client_role = SubRole.find_by(name: 'client')
User.where(classification: :client).find_each do |user|
  user.grant_sub_role!(client_role.id, granted_via: 'migration')
end

# Назначить всем инструкторам соответствующие роли
User.where(classification: :instructor_1).find_each do |user|
  user.grant_sub_role!('instructor_1', granted_via: 'migration')
end
```

---

## Roadmap (опционально)

### Возможные улучшения:
- [ ] Группы ролей для упрощения управления
- [ ] Временные роли с auto-expiration
- [ ] История изменений ролей пользователя
- [ ] Bulk assignment ролей (назначить роль нескольким пользователям)
- [ ] Export/Import настроек доступа
- [ ] Визуализация иерархии ролей
- [ ] API endpoints для управления ролями

---

## Support

**Документация:** `/Users/avdemkin/code_vibe/sbf/SUB_ROLES_IMPLEMENTATION.md`
**Тесты:** `spec/models/sub_role_spec.rb`, `spec/integration/order_request_sub_role_assignment_spec.rb`
**Миграции:** `db/migrate/*_create_sub_roles.rb` (5 файлов)

**Контакты разработчика:** Claude Code AI Assistant
**Дата:** 2026-02-05
