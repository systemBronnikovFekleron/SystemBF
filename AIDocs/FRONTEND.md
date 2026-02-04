# Frontend Design - Система Бронникова

## 🎨 Концепция дизайна

**Aesthetic Direction:** "Spiritual Minimalism meets Modern Technology"

### Ключевые характеристики:
- Сочетание духовного (мягкие градиенты, плавные формы) и технологичного (четкая типографика, grid-системы)
- Уникальная цветовая палитра: глубокий индиго → аметистовый → золотой акцент
- Русская типографика: IBM Plex Sans + IBM Plex Serif
- Анимации: плавные, медитативные переходы с эффектом glassmorphism

---

## 🎨 Design System

### Цветовая палитра

**Primary (Indigo):**
```css
--color-primary-50: #eef2ff   (очень светлый)
--color-primary-600: #4f46e5  (основной)
--color-primary-900: #312e81  (очень темный)
```

**Secondary (Amethyst):**
```css
--color-secondary-50: #faf5ff
--color-secondary-600: #9333ea
--color-secondary-900: #581c87
```

**Accent (Gold):**
```css
--color-accent: #f59e0b
```

**Gradients:**
- Фоновый градиент: `linear-gradient(135deg, #f8fafc 0%, #eef2ff 50%, #faf5ff 100%)`
- Текстовый градиент: `linear-gradient(135deg, var(--color-primary-600), var(--color-secondary-600))`

### Типографика

**Шрифты:**
- Основной: `IBM Plex Sans` (300, 400, 500, 600, 700)
- Акцидентный: `IBM Plex Serif` (400, 600)

**Размеры:**
```css
h1: 3rem (48px)
h2: 2.25rem (36px)
h3: 1.875rem (30px)
body: 16px
small: 0.875rem (14px)
```

### Spacing System

```css
--spacing-xs: 0.25rem   (4px)
--spacing-sm: 0.5rem    (8px)
--spacing-md: 1rem      (16px)
--spacing-lg: 1.5rem    (24px)
--spacing-xl: 2rem      (32px)
--spacing-2xl: 3rem     (48px)
```

### Shadows

```css
--shadow-sm: 0 1px 2px 0 rgba(0, 0, 0, 0.05)
--shadow-md: 0 4px 6px -1px rgba(0, 0, 0, 0.1)
--shadow-lg: 0 10px 15px -3px rgba(0, 0, 0, 0.1)
--shadow-glow: 0 0 20px rgba(99, 102, 241, 0.3)
```

---

## 📦 Компоненты

### Cards

**Базовая карточка:**
```css
background: rgba(255, 255, 255, 0.9)
backdrop-filter: blur(10px)
border-radius: var(--radius-xl)
border: 1px solid rgba(255, 255, 255, 0.5)
```

**Эффекты:**
- Hover: `transform: translateY(-4px)` + увеличенная тень
- Top border gradient появляется при hover
- Shimmer анимация на product images

### Buttons

**Типы:**
- `.btn-primary` - основная кнопка (indigo gradient)
- `.btn-secondary` - вторичная кнопка (amethyst gradient)
- `.btn-outline` - outline кнопка
- `.btn-ghost` - прозрачная кнопка

**Размеры:**
- `.btn-sm` - маленькая
- `.btn` - средняя (по умолчанию)
- `.btn-lg` - большая

**Эффекты:**
- Ripple эффект при клике (::before pseudo-element)
- Transform на hover: `translateY(-2px)`
- Увеличенная тень на hover

### Badges

**Типы:**
- `.badge-primary` - индиго
- `.badge-featured` - золотой градиент с тенью
- `.badge-success` - зеленый
- `.badge-warning` - оранжевый
- `.badge-error` - красный

### Navbar

- Fixed position с backdrop-filter blur
- Smooth scroll transition
- Active link с bottom gradient border
- Responsive: скрывается меню на мобильных

### Stat Cards

- Pulse анимация на фоне
- Gradient text для значений
- Icon + Value + Label структура

---

## 🎬 Анимации

### Базовые анимации:

**fadeIn:**
```css
@keyframes fadeIn {
  from { opacity: 0; transform: translateY(20px); }
  to { opacity: 1; transform: translateY(0); }
}
```

**pulse:**
```css
@keyframes pulse {
  0%, 100% { transform: scale(1); opacity: 0.5; }
  50% { transform: scale(1.05); opacity: 0.8; }
}
```

**shimmer:**
```css
@keyframes shimmer {
  0%, 100% { opacity: 0.3; transform: translateX(-100%); }
  50% { opacity: 0.8; transform: translateX(100%); }
}
```

### Staggered animations:

Используйте классы `.stagger-1` ... `.stagger-6` для последовательной анимации элементов:
```css
.stagger-1 { animation-delay: 0.1s; }
.stagger-2 { animation-delay: 0.2s; }
```

---

## 📱 Страницы

### Главная страница (`/`)

**Секции:**
1. **Hero Section** - заголовок с gradient text, CTA кнопки
2. **Featured Products** - 3 избранных продукта
3. **Features** - 6 основных возможностей платформы
4. **Recent Products** - последние 6 продуктов
5. **CTA Section** - призыв к действию с gradient фоном

### Магазин (`/products`)

**Элементы:**
- Фильтры по категориям и типам
- Grid с карточками продуктов
- Hover эффекты на карточках
- Badges для типов и избранных

### Страница продукта (`/products/:slug`)

**Структура:**
- Breadcrumbs навигация
- Grid: изображение + информация (2 колонки)
- Product Stats (тип, рейтинг, ученики)
- Действия: "Добавить в корзину" + "Купить сейчас"
- Описание и "Что входит" секции
- Похожие продукты

---

## 🛠️ Технические детали

### Glassmorphism эффект:

```css
background: rgba(255, 255, 255, 0.9);
backdrop-filter: blur(10px);
border: 1px solid rgba(255, 255, 255, 0.5);
```

### Gradient text:

```css
background: linear-gradient(135deg, var(--color-primary-600), var(--color-secondary-600));
-webkit-background-clip: text;
-webkit-text-fill-color: transparent;
background-clip: text;
```

### Grid system:

```css
.grid { display: grid; gap: var(--spacing-lg); }
.md\:grid-cols-3 { grid-template-columns: repeat(3, 1fr); }
```

---

## 📂 Структура файлов

```
app/
├── assets/
│   └── stylesheets/
│       └── application.css       # Главный файл стилей
├── views/
│   ├── layouts/
│   │   └── application.html.erb  # Главный layout
│   ├── shared/
│   │   ├── _navbar.html.erb       # Навбар
│   │   ├── _flash.html.erb        # Flash сообщения
│   │   └── _footer.html.erb       # Футер
│   ├── home/
│   │   └── index.html.erb         # Главная страница
│   └── products/
│       ├── index.html.erb         # Каталог
│       └── show.html.erb          # Продукт
└── helpers/
    ├── application_helper.rb      # Общие helpers
    └── products_helper.rb         # Product helpers
```

---

## 🎯 Уникальные особенности дизайна

### 1. Spiritual Minimalism
- Чистые, просторные layouts
- Мягкие градиенты без резких переходов
- Успокаивающая цветовая палитра

### 2. Modern Technology
- Glassmorphism эффекты
- Продуманные анимации
- Современная grid-система

### 3. Медитативные переходы
- Все анимации: 300ms-500ms cubic-bezier
- Плавные hover эффекты
- Staggered animations для групп элементов

### 4. Attention to detail
- Custom ::before pseudo-elements для эффектов
- Shimmer анимация на product images
- Pulse анимация на stat cards
- Ripple эффект на кнопках

---

## 🚀 Запуск

```bash
# Запустить Rails сервер
rails server

# Открыть в браузере
http://localhost:3000
```

### Доступные страницы:

- `/` - Главная
- `/products` - Каталог продуктов
- `/products/:slug` - Страница продукта
- `/categories` - Категории

---

## 📝 TODO (будущие улучшения)

- [ ] Страница корзины (`/cart`)
- [ ] Страница личного кабинета (`/dashboard`)
- [ ] Страница заказов (`/orders`)
- [ ] Страница входа/регистрации
- [ ] Mobile menu (responsive navbar)
- [ ] Dark mode toggle
- [ ] Accessibility improvements (ARIA labels)
- [ ] Skeleton loaders
- [ ] Toast notifications вместо flash
- [ ] Infinite scroll для каталога
- [ ] Product image gallery
- [ ] Reviews & ratings компонент

---

## 🎨 Вдохновение

Дизайн вдохновлен:
- **Spiritual aesthetics:** мягкие градиенты, плавные формы
- **Modern SaaS platforms:** чистые layouts, glassmorphism
- **Educational platforms:** ясная типографика, карточки курсов
- **Minimalism:** максимум воздуха, минимум отвлекающих элементов

---

**Дизайн готов к дальнейшему развитию! ✨**
