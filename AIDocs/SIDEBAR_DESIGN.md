# 📱 Sidebar Dashboard Design

## Концепция дизайна с левым сайдбаром

**Layout:** Фиксированный левый sidebar (280px) + динамическая главная область

### Преимущества sidebar дизайна:
- 🎯 Постоянная навигация всегда на виду
- 📊 Быстрый доступ к статистике (баланс, рейтинг)
- 👤 Профиль пользователя всегда виден
- 🧭 Удобная навигация по разделам
- 📱 Responsive: скрывается на мобильных

---

## 🎨 Структура Sidebar

### 1. Header (Logo)
```
✧ Система Бронникова
Личный кабинет
```
- Gradient text для названия
- Ссылка на главную страницу

### 2. Profile Card
```
┌─────────────────────────┐
│  👤                      │
│  Имя Фамилия            │
│  [Клиент]          ⚙️   │
└─────────────────────────┘
```
- Аватар (4rem)
- Имя и классификация
- Кнопка настроек

### 3. Stats Cards (2 карточки)
```
┌───────────────┐
│ 💰 Баланс     │
│ 1.000,00 ₽   │
└───────────────┘

┌───────────────┐
│ ⭐ Рейтинг    │
│ 50 очков      │
│ Уровень 1     │
└───────────────┘
```

### 4. Navigation
**Главное:**
- 🏠 Обзор
- 👤 Профиль
- 💳 Кошелек (с балансом)
- ⭐ Рейтинг (с уровнем)

**Обучение:**
- 🎓 Мои курсы (с количеством)
- 🛍️ Магазин
- 📦 Мои заказы

**Дополнительно:**
- 🏆 Достижения
- 🔔 Уведомления (с badge)
- ⚙️ Настройки

### 5. Footer
- 🚪 Выйти (кнопка)

---

## 🎨 Стили Sidebar

### Основной контейнер:
```css
.dashboard-sidebar {
  position: fixed;
  left: 0;
  width: 280px;
  height: 100vh;
  background: rgba(255, 255, 255, 0.95);
  backdrop-filter: blur(12px);
  border-right: 1px solid rgba(99, 102, 241, 0.1);
}
```

### Навигационные элементы:
```css
.sidebar-nav-item {
  padding: 0.75rem 1.5rem;
  display: flex;
  align-items: center;
  gap: 0.75rem;
  transition: all 0.2s;
}

/* Active state */
.sidebar-nav-item.active {
  background: linear-gradient(90deg, rgba(99, 102, 241, 0.1), transparent);
  color: var(--color-primary-600);
  border-left: 3px solid var(--color-primary-600);
}
```

### Stat Cards:
```css
.sidebar-stat {
  padding: 1rem;
  background: linear-gradient(135deg, rgba(99, 102, 241, 0.05), rgba(168, 85, 247, 0.05));
  border-radius: 0.75rem;
  border: 1px solid rgba(99, 102, 241, 0.1);
}
```

---

## 📱 Main Content Area

### Header:
```css
.dashboard-header {
  background: rgba(255, 255, 255, 0.8);
  backdrop-filter: blur(12px);
  border-bottom: 1px solid rgba(99, 102, 241, 0.1);
  position: sticky;
  top: 0;
  padding: 1.5rem 2rem;
}
```

**Содержимое:**
- Заголовок страницы + подзаголовок
- Quick actions (корзина, уведомления)

### Content Area:
```css
.dashboard-content {
  flex: 1;
  padding: 2rem;
}
```

---

## 📄 Страницы Dashboard

### 1. Обзор (/dashboard)

**Секции:**
```
┌─────────────────────────────────────┐
│ Приветственный баннер (gradient)    │
│ "Добро пожаловать, Имя! 👋"        │
│ [Исследовать курсы] [Мои курсы →]  │
└─────────────────────────────────────┘

┌───────┬───────┬───────┬───────┐
│ 💰    │ ⭐    │ 📦    │ 🎓    │
│ Баланс│Рейтинг│Заказы │Курсы  │
└───────┴───────┴───────┴───────┘

┌──────────────────┬──────────┐
│ Последние заказы │Мои курсы │
│                  │          │
│ [Grid заказов]   │ [List]   │
│                  │          │
│                  │Быстрые   │
│                  │действия  │
└──────────────────┴──────────┘
```

### 2. Профиль (/dashboard/profile)
- Редактирование личных данных
- Изменение пароля
- Аватар

### 3. Кошелек (/dashboard/wallet)
- Текущий баланс
- История транзакций
- Пополнение кошелька
- Вывод средств (если доступно)

### 4. Рейтинг (/dashboard/rating)
- Текущий уровень
- Прогресс до следующего уровня
- История начисления очков
- Как заработать больше очков

### 5. Мои заказы (/dashboard/orders)
- Список всех заказов
- Фильтры по статусу
- Детали заказа

---

## 🎯 Ключевые компоненты

### Welcome Banner
```html
<div class="card" style="
  background: linear-gradient(135deg, var(--color-primary-600), var(--color-secondary-600));
  color: white;
  position: relative;
  overflow: hidden;
">
  <!-- Dot pattern background -->
  <div style="
    position: absolute;
    inset: 0;
    background-image: radial-gradient(circle, rgba(255, 255, 255, 0.1) 1px, transparent 1px);
    background-size: 30px 30px;
    opacity: 0.3;
  "></div>

  <!-- Content -->
</div>
```

### Stat Cards
```html
<div class="stat-card">
  <div class="stat-icon">💰</div>
  <div class="stat-value">1.000,00 ₽</div>
  <div class="stat-label">Баланс кошелька</div>
  <a href="/dashboard/wallet">Пополнить →</a>
</div>
```

### Order Card
```html
<div style="
  padding: 1rem;
  border: 1px solid var(--color-gray-200);
  border-radius: 0.75rem;
  transition: all 0.2s;
  cursor: pointer;
">
  <div style="display: flex; justify-content: space-between;">
    <div>
      <div>Заказ #ORD-123456</div>
      <div>01.02.2026 18:30</div>
    </div>
    <div>
      <div>15.000,00 ₽</div>
      <span class="badge badge-success">Оплачен</span>
    </div>
  </div>
</div>
```

### Course Card (в sidebar My Courses)
```html
<div style="
  padding: 1rem;
  border: 1px solid var(--color-gray-200);
  border-radius: 0.75rem;
">
  <div style="display: flex; align-items: center; gap: 0.75rem;">
    <div style="
      width: 3rem;
      height: 3rem;
      border-radius: 0.5rem;
      background: gradient;
      display: flex;
      align-items: center;
      justify-content: center;
    ">🎓</div>

    <div>
      <div>Название курса</div>
      <div>Курс</div>
    </div>
  </div>

  <!-- Progress bar -->
  <div style="margin-top: 0.75rem;">
    <div style="display: flex; justify-content: space-between;">
      <span>Прогресс</span>
      <span>60%</span>
    </div>
    <div style="width: 100%; height: 4px; background: gray; border-radius: 2px;">
      <div style="width: 60%; height: 100%; background: gradient;"></div>
    </div>
  </div>
</div>
```

---

## 📱 Mobile Responsive

### Поведение на мобильных:

**Sidebar:**
- По умолчанию скрыт (`transform: translateX(-100%)`)
- Открывается через floating button
- Overlay затемнение при открытии
- Закрывается при клике вне sidebar

**Main Content:**
- Занимает всю ширину (`margin-left: 0`)
- Header всегда видим
- Content адаптируется

**Floating Toggle Button:**
```css
.mobile-sidebar-toggle {
  position: fixed;
  bottom: 2rem;
  right: 2rem;
  width: 3.5rem;
  height: 3.5rem;
  border-radius: 50%;
  background: linear-gradient(135deg, var(--color-primary-600), var(--color-secondary-600));
  box-shadow: 0 8px 20px rgba(99, 102, 241, 0.4);
  z-index: 1001;
}
```

---

## 🎨 Цветовая схема Dashboard

**Gradient backgrounds:**
- Primary gradient: `linear-gradient(135deg, #4f46e5, #9333ea)`
- Subtle gradient: `linear-gradient(135deg, rgba(99, 102, 241, 0.05), rgba(168, 85, 247, 0.05))`

**Active states:**
- Active nav: `rgba(99, 102, 241, 0.1)` + left border gradient
- Hover: `rgba(99, 102, 241, 0.05)`

**Cards:**
- White с 95% opacity + backdrop-filter
- Border: `rgba(99, 102, 241, 0.1)`

---

## 🚀 Доступные маршруты

```
GET /dashboard                  # Обзор
GET /dashboard/profile          # Профиль
GET /dashboard/wallet           # Кошелек
GET /dashboard/rating           # Рейтинг
GET /dashboard/orders           # Заказы
GET /dashboard/my-courses       # Мои курсы
GET /dashboard/achievements     # Достижения
GET /dashboard/notifications    # Уведомления
GET /dashboard/settings         # Настройки
```

---

## 💡 Улучшения (TODO)

- [ ] Страницы Profile, Wallet, Rating (полные версии)
- [ ] Страница My Courses с прогрессом
- [ ] Achievements система
- [ ] Notifications центр
- [ ] Settings страница
- [ ] Mobile menu анимации
- [ ] Real-time updates для уведомлений
- [ ] Drag & drop для аватара
- [ ] Charts для статистики (Chart.js)
- [ ] Dark mode toggle

---

**Dashboard с sidebar готов к использованию! ✨**

Запустите `http://localhost:3000/dashboard` для просмотра.
