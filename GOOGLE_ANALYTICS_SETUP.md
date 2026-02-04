# Google Analytics 4 Integration Guide

## 📊 Обзор

Платформа интегрирована с **Google Analytics 4 (GA4)** для отслеживания:

### Tracked Events:

1. **Page Views** - автоматически на всех страницах
2. **view_item** - просмотр страницы продукта
3. **add_to_cart** - добавление товара в корзину
4. **purchase** - завершенная покупка

### E-commerce Data:
- Product ID, Name, Category, Price
- Transaction ID (order_number)
- Purchase value в RUB

---

## 🚀 Настройка (Setup)

### Шаг 1: Создание GA4 Property

1. Перейдите на [Google Analytics](https://analytics.google.com/)
2. Создайте новый **GA4 Property**:
   - Admin → Create Property
   - Property name: "Система Бронникова"
   - Time zone: Russia/Moscow
   - Currency: Russian Ruble (RUB)

3. Создайте **Data Stream**:
   - Platform: Web
   - Website URL: https://bronnikov.com (или ваш домен)
   - Stream name: "Production Website"

4. Скопируйте **Measurement ID** (формат: `G-XXXXXXXXXX`)

---

### Шаг 2: Настройка Credentials

Откройте Rails credentials:

```bash
EDITOR="nano" rails credentials:edit
```

Добавьте:

```yaml
google_analytics:
  measurement_id: G-XXXXXXXXXX
```

Замените `G-XXXXXXXXXX` на ваш реальный Measurement ID.

Сохраните файл (Ctrl+O, Enter, Ctrl+X в nano).

---

### Шаг 3: Проверка интеграции

1. Запустите Rails сервер:

```bash
rails server
```

2. Откройте браузер в режиме инкогнито

3. Перейдите на любую страницу сайта

4. Откройте **Google Analytics Realtime Report**:
   - Analytics → Reports → Realtime
   - Вы должны увидеть себя в списке активных пользователей

---

## 🧪 Тестирование Events

### Development Mode

В development режиме GA script **не загружается** (только в production).

Для тестирования в development:

1. Временно измените условие в `app/views/shared/_google_analytics.html.erb`:

```erb
<% if Rails.application.credentials.dig(:google_analytics, :measurement_id).present? %>
```

Замените `Rails.env.production?` на `true` или уберите это условие.

2. Перезапустите сервер

3. Откройте browser console (F12)

4. Перейдите на страницу продукта - вы увидите:
```
[GA] View Item: Название продукта
```

5. Нажмите "Добавить в корзину":
```
[GA] Add to Cart: Название продукта
```

---

### Production Testing

После деплоя на production:

1. Откройте **GA4 Realtime** → Events

2. Тестируйте события:

| Действие | Событие GA4 | Где проверить |
|----------|-------------|---------------|
| Открыть страницу продукта | `view_item` | Realtime → Events |
| Добавить в корзину | `add_to_cart` | Realtime → Events |
| Завершить покупку | `purchase` | Realtime → Events + Conversions |

3. Проверьте параметры событий:
   - Event → Event details
   - Должны быть: `item_id`, `item_name`, `price`, `currency`

---

## 📈 Настройка E-commerce Reports

### Включение Enhanced Measurement

1. Admin → Data Streams → (ваш stream) → Enhanced measurement
2. Убедитесь что включены:
   - ✅ Page views
   - ✅ Scrolls
   - ✅ Outbound clicks
   - ✅ Site search
   - ✅ Video engagement
   - ✅ File downloads

---

### Настройка Conversions

1. Admin → Events → Mark as conversion:
   - `purchase` (уже должен быть отмечен)
   - Опционально: `add_to_cart`

2. Проверьте Conversions:
   - Reports → Engagement → Conversions
   - После первых покупок появятся данные

---

### E-commerce Purchases Report

1. Перейдите: Reports → Monetization → Ecommerce purchases

2. Вы увидите:
   - Revenue
   - Transactions
   - Average purchase revenue
   - Items viewed, added to cart, purchased

---

## 🛠 Интеграция в код (уже реализовано)

### 1. Layout Integration

Файл: `app/views/layouts/application.html.erb`

```erb
<%= render 'shared/google_analytics' %>
```

GA script загружается на **всех страницах** в production.

---

### 2. Analytics Controller

Файл: `app/javascript/controllers/analytics_controller.js`

**Методы:**

- `trackViewItem()` - просмотр продукта
- `trackAddToCart()` - добавление в корзину
- `trackPurchase()` - завершенная покупка
- `trackBeginCheckout()` - начало оформления (опционально)

**Использование через data attributes:**

```erb
<div data-controller="analytics"
     data-analytics-event-value="view_item"
     data-analytics-product-id-value="<%= product.id %>"
     data-analytics-product-name-value="<%= product.name %>"
     data-analytics-price-value="<%= product.price_kopecks / 100.0 %>"
     data-analytics-category-value="<%= product.category.name %>">
  <!-- Content -->
</div>
```

---

### 3. Product View Tracking

Файл: `app/views/products/show.html.erb`

Автоматически отправляет `view_item` при загрузке страницы.

---

### 4. Add to Cart Tracking

Файл: `app/views/products/show.html.erb`

Кнопка "Добавить в корзину":

```erb
<%= button_to "🛒 Добавить в корзину",
              add_item_cart_path(product_id: @product.id),
              method: :post,
              data: { action: "click->analytics#trackAddToCart" } %>
```

---

### 5. Purchase Tracking

Файл: `app/views/orders/show.html.erb`

Автоматически отправляет `purchase` при просмотре **paid** заказа.

**Data structure:**

```javascript
{
  transaction_id: "BR-2026-0001",
  value: 3000.00,
  currency: "RUB",
  items: [
    {
      item_id: 1,
      item_name: "Основы видения",
      item_category: "Курсы",
      price: 3000.00,
      quantity: 1
    }
  ]
}
```

---

## 🎯 Custom Events (расширение)

### Добавление новых событий

Если нужно отследить дополнительные действия:

```erb
<!-- В view -->
<button data-controller="analytics"
        data-action="click->analytics#trackEvent"
        data-analytics-event-name="button_click"
        data-analytics-button-name="Download PDF">
  Скачать материалы
</button>
```

```javascript
// В analytics_controller.js
trackEvent() {
  const eventName = this.element.dataset.analyticsEventName
  const params = {
    button_name: this.element.dataset.analyticsButtonName
  }

  gtag('event', eventName, params)
}
```

---

## 🔍 Debugging

### Browser Console

Откройте DevTools Console (F12) и проверьте:

```javascript
// Проверка загрузки gtag
typeof gtag  // должно быть "function"

// Проверка dataLayer
window.dataLayer  // должен быть массив с событиями

// Ручная отправка тестового события
gtag('event', 'test_event', { test_param: 'value' })
```

---

### GA4 Debug View

1. Установите **GA Debugger** Chrome extension
2. Включите extension
3. Откройте сайт
4. Перейдите: Admin → DebugView
5. Все события будут отображаться в реальном времени

---

## 📊 Полезные отчеты

### 1. E-commerce Overview

**Reports → Monetization → Overview**

- Total revenue
- Transactions
- Average purchase value
- Revenue by product

---

### 2. User Acquisition

**Reports → Acquisition → User acquisition**

- Откуда приходят пользователи
- Какие каналы приносят больше конверсий

---

### 3. Funnel Exploration

**Explore → Funnel exploration**

Создайте воронку:
1. `view_item` (просмотр продукта)
2. `add_to_cart` (добавление в корзину)
3. `begin_checkout` (начало оформления - если реализовано)
4. `purchase` (покупка)

Это покажет где пользователи "отваливаются".

---

### 4. Custom Reports

**Explore → Create custom report**

Примеры метрик:
- Конверсия просмотр → покупка
- Средний чек по категориям
- Top products по revenue
- User lifetime value

---

## 🔐 Privacy & GDPR

### Anonymize IP (уже включено)

В `_google_analytics.html.erb`:

```javascript
gtag('config', 'G-XXXXXXXXXX', {
  'anonymize_ip': true  // GDPR compliance
});
```

---

### Cookie Consent

Если требуется cookie banner (EU GDPR):

1. Добавьте cookie consent banner
2. Загружайте GA только после согласия:

```javascript
// После получения согласия
if (userConsented) {
  loadGoogleAnalytics()
}
```

---

## ⚙️ Environment Variables

Альтернатива credentials (через ENV):

```ruby
# config/initializers/google_analytics.rb
Rails.application.config.google_analytics_id = ENV['GA_MEASUREMENT_ID']
```

```erb
<!-- app/views/shared/_google_analytics.html.erb -->
<% if Rails.application.config.google_analytics_id.present? %>
  <script async src="https://www.googletagmanager.com/gtag/js?id=<%= Rails.application.config.google_analytics_id %>"></script>
  ...
<% end %>
```

**.env:**
```
GA_MEASUREMENT_ID=G-XXXXXXXXXX
```

---

## ✅ Checklist

- [ ] Создан GA4 property
- [ ] Скопирован Measurement ID
- [ ] Добавлен в credentials: `google_analytics.measurement_id`
- [ ] Протестированы события в Realtime
- [ ] Настроены conversions (purchase)
- [ ] Проверен E-commerce report
- [ ] Включен anonymize_ip для GDPR
- [ ] (Опционально) Настроен cookie consent banner

---

## 🆘 Troubleshooting

### GA script не загружается

**Причина**: Работает только в production

**Решение**:
- Проверьте `Rails.env.production?` в partial
- Или временно измените условие для тестирования

---

### События не отправляются

**Причины:**
1. `gtag` не определен (GA не загружен)
2. AdBlocker блокирует GA

**Решение:**
- Откройте консоль: `typeof gtag`
- Отключите AdBlocker для тестирования
- Проверьте Network tab: запросы к `google-analytics.com`

---

### Данные не появляются в отчетах

**Причина**: Отчеты обновляются с задержкой 24-48 часов

**Решение**:
- Используйте **Realtime** для мгновенной проверки
- Подождите 24 часа для полных отчетов

---

## 📚 Дополнительные ресурсы

- [GA4 Documentation](https://support.google.com/analytics/answer/9304153)
- [Enhanced E-commerce Guide](https://support.google.com/analytics/answer/9267735)
- [gtag.js Reference](https://developers.google.com/analytics/devguides/collection/gtagjs)
- [GA4 Event Reference](https://support.google.com/analytics/answer/9267735)
