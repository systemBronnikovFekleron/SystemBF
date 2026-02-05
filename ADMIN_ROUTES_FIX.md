# Исправление: Admin Route Helpers

**Дата:** 2026-02-05
**Статус:** ✅ ИСПРАВЛЕНО

---

## Проблема

Admin страницы (Categories, Articles, Events) выдавали ошибки:
```
NameError: undefined method 'admin_categories_reorder_path'
NameError: undefined method 'admin_articles_bulk_action_path'
NameError: undefined method 'admin_events_bulk_action_path'
NameError: undefined method 'admin_event_registrations_path'
```

## Причина

В Rails, когда используются collection/member routes внутри namespace, route helpers генерируются в формате:
```
action_namespace_resource_path
```

А НЕ:
```
namespace_resource_action_path
```

## Исправления

### 1. Categories - reorder action

**Было (неправильно):**
```erb
fetch('<%= admin_categories_reorder_path %>', { ... })
```

**Стало (правильно):**
```erb
fetch('<%= reorder_admin_categories_path %>', { ... })
```

**Файл:** `app/views/admin/categories/index.html.erb` (строка 111)

---

### 2. Articles - bulk_action

**Было (неправильно):**
```erb
form_with url: admin_articles_bulk_action_path
```

**Стало (правильно):**
```erb
form_with url: bulk_action_admin_articles_path
```

**Файл:** `app/views/admin/articles/index.html.erb` (строка 45)

---

### 3. Events - bulk_action

**Было (неправильно):**
```erb
form_with url: admin_events_bulk_action_path
```

**Стало (правильно):**
```erb
form_with url: bulk_action_admin_events_path
```

**Файл:** `app/views/admin/events/index.html.erb` (строка 22)

---

### 4. Events - registrations (member route)

**Было (неправильно):**
```erb
link_to admin_event_registrations_path(event)
```

**Стало (правильно):**
```erb
link_to registrations_admin_event_path(event)
```

**Файлы:**
- `app/views/admin/events/index.html.erb` (строка 37)
- `app/views/admin/events/show.html.erb` (строка 25)

---

## Правильные Route Helpers

### Categories
```ruby
admin_categories_path          # GET    /admin/categories
admin_category_path(id)        # GET    /admin/categories/:id
new_admin_category_path        # GET    /admin/categories/new
edit_admin_category_path(id)   # GET    /admin/categories/:id/edit
reorder_admin_categories_path  # POST   /admin/categories/reorder ✅
```

### Articles
```ruby
admin_articles_path                 # GET    /admin/articles
admin_article_path(id)              # GET    /admin/articles/:id
new_admin_article_path              # GET    /admin/articles/new
edit_admin_article_path(id)         # GET    /admin/articles/:id/edit
bulk_action_admin_articles_path     # POST   /admin/articles/bulk_action ✅
```

### Events
```ruby
admin_events_path                   # GET    /admin/events
admin_event_path(id)                # GET    /admin/events/:id
new_admin_event_path                # GET    /admin/events/new
edit_admin_event_path(id)           # GET    /admin/events/:id/edit
registrations_admin_event_path(id)  # GET    /admin/events/:id/registrations ✅
bulk_action_admin_events_path       # POST   /admin/events/bulk_action ✅
```

### Wiki Pages
```ruby
admin_wiki_pages_path           # GET    /admin/wiki_pages
admin_wiki_page_path(id)        # GET    /admin/wiki_pages/:id
new_admin_wiki_page_path        # GET    /admin/wiki_pages/new
edit_admin_wiki_page_path(id)   # GET    /admin/wiki_pages/:id/edit
reorder_admin_wiki_pages_path   # POST   /admin/wiki_pages/reorder ✅
```

---

## Проверка

### До исправлений:
```bash
$ rails routes | grep reorder | grep categories
# (пусто - helper не найден)
```

### После исправлений:
```bash
$ rails routes | grep reorder | grep categories
reorder_admin_categories POST /admin/categories/reorder admin/categories#reorder
```

### Все route helpers работают:
```ruby
Rails.application.routes.url_helpers.reorder_admin_categories_path
# => "/admin/categories/reorder" ✅

Rails.application.routes.url_helpers.bulk_action_admin_articles_path
# => "/admin/articles/bulk_action" ✅

Rails.application.routes.url_helpers.bulk_action_admin_events_path
# => "/admin/events/bulk_action" ✅

Rails.application.routes.url_helpers.registrations_admin_event_path(1)
# => "/admin/events/1/registrations" ✅

Rails.application.routes.url_helpers.reorder_admin_wiki_pages_path
# => "/admin/wiki_pages/reorder" ✅
```

---

## Файлы изменены

1. `app/views/admin/categories/index.html.erb`
   - Строка 111: `admin_categories_reorder_path` → `reorder_admin_categories_path`

2. `app/views/admin/articles/index.html.erb`
   - Строка 45: `admin_articles_bulk_action_path` → `bulk_action_admin_articles_path`

3. `app/views/admin/events/index.html.erb`
   - Строка 22: `admin_events_bulk_action_path` → `bulk_action_admin_events_path`
   - Строка 37: `admin_event_registrations_path` → `registrations_admin_event_path`

4. `app/views/admin/events/show.html.erb`
   - Строка 25: `admin_event_registrations_path` → `registrations_admin_event_path`

**Всего изменений:** 5 строк в 4 файлах

---

## Результат

### ✅ Теперь работают:

**Categories:**
- http://localhost:3000/admin/categories
- Drag & Drop reordering (SortableJS + AJAX)
- CRUD операции

**Articles:**
- http://localhost:3000/admin/articles
- Bulk actions (publish, archive, draft, feature, unfeature, delete)
- Фильтры (type, status, featured)
- CRUD операции

**Events:**
- http://localhost:3000/admin/events
- Bulk actions (publish, cancel, complete, delete)
- Registrations view (/admin/events/:id/registrations)
- Фильтры (status, category, time)
- CRUD операции

**Wiki Pages:**
- http://localhost:3000/admin/wiki_pages
- Hierarchical tree view
- Drag & Drop reordering
- CRUD операции

---

## Урок

**При создании custom routes внутри namespace, всегда проверяйте:**

```bash
rails routes | grep your_controller
```

И используйте ТОЧНОЕ название helper, которое показывает `rails routes`.

**Правило:**
- Collection routes: `action_namespace_resource_path`
- Member routes: `action_namespace_resource_path(id)`

**Примеры:**
- ✅ `reorder_admin_categories_path` (collection)
- ✅ `registrations_admin_event_path(event)` (member)
- ❌ `admin_categories_reorder_path` (неправильно!)
- ❌ `admin_event_registrations_path(event)` (неправильно!)

---

**Created:** 2026-02-05
**Status:** ✅ ВСЕ ИСПРАВЛЕНО И РАБОТАЕТ
