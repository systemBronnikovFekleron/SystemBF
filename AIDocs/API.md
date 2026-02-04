# API Documentation - Платформа "Система Бронникова"

## Базовый URL
```
http://localhost:3000
```

## Аутентификация

### POST /api/v1/login
Вход в систему с получением JWT токена.

**Request:**
```json
{
  "email": "client@example.com",
  "password": "password123"
}
```

**Response (200 OK):**
```json
{
  "token": "eyJhbGciOiJIUzI1NiJ9...",
  "user": {
    "id": 1,
    "email": "client@example.com",
    "first_name": "Алексей",
    "last_name": "Иванов",
    "classification": "client",
    "active": true
  }
}
```

**Заметка:** JWT токен также устанавливается в httpOnly cookie `jwt_token`.

### DELETE /api/v1/logout
Выход из системы.

**Response (200 OK):**
```json
{
  "message": "Logged out successfully"
}
```

### GET /api/v1/validate_token
Валидация JWT токена (для WordPress SSO).

**Headers:**
```
Authorization: Bearer YOUR_JWT_TOKEN
```

**Response (200 OK):**
```json
{
  "valid": true,
  "user": {
    "id": 1,
    "email": "client@example.com",
    "first_name": "Алексей",
    "last_name": "Иванов",
    "classification": "client",
    "active": true
  }
}
```

## Пользователи

### GET /api/v1/users/:id
Получение информации о пользователе.

**Headers:**
```
Authorization: Bearer YOUR_JWT_TOKEN
```

**Response (200 OK):**
```json
{
  "id": 1,
  "email": "client@example.com",
  "first_name": "Алексей",
  "last_name": "Иванов",
  "classification": "client",
  "active": true,
  "profile": {
    "phone": null,
    "birth_date": null,
    "city": null,
    "country": "RU"
  },
  "wallet": {
    "balance": "1.000,00 ₽"
  },
  "rating": {
    "points": 50,
    "level": 1
  }
}
```

### PATCH /api/v1/users/:id
Обновление данных пользователя.

**Headers:**
```
Authorization: Bearer YOUR_JWT_TOKEN
```

**Request:**
```json
{
  "user": {
    "first_name": "Новое Имя",
    "password": "newpassword123",
    "password_confirmation": "newpassword123"
  }
}
```

**Response (200 OK):**
```json
{
  "message": "User updated successfully"
}
```

## Категории

### GET /categories
Получение списка всех категорий.

**Response (200 OK):**
```json
[
  {
    "id": 1,
    "name": "Курсы",
    "slug": "kursy",
    "description": "Обучающие курсы по методу Бронникова",
    "position": 1,
    "created_at": "2026-02-01T18:50:00.000Z",
    "updated_at": "2026-02-01T18:50:00.000Z"
  }
]
```

### GET /categories/:id
Получение категории с продуктами.

**Response (200 OK):**
```json
{
  "category": {
    "id": 1,
    "name": "Курсы",
    "slug": "kursy"
  },
  "products": [
    {
      "id": 1,
      "name": "Базовый курс",
      "slug": "bazovyi-kurs",
      "description": "Введение в метод Бронникова...",
      "price": "15.000,00 ₽",
      "product_type": "course",
      "featured": true
    }
  ]
}
```

## Продукты

### GET /products
Получение списка продуктов.

**Query параметры:**
- `category_id` - фильтр по категории
- `product_type` - фильтр по типу (video, book, course, service, event_access)
- `featured=true` - только избранные

**Примеры:**
```
GET /products
GET /products?category_id=1
GET /products?product_type=course
GET /products?featured=true
```

**Response (200 OK):**
```json
[
  {
    "id": 1,
    "name": "Базовый курс",
    "slug": "bazovyi-kurs",
    "description": "Введение в метод Бронникова...",
    "price": "15.000,00 ₽",
    "price_kopecks": 1500000,
    "product_type": "course",
    "status": "published",
    "featured": true,
    "category": "Курсы"
  }
]
```

### GET /products/:id
Получение информации о продукте.

**Response (200 OK):**
```json
{
  "id": 1,
  "name": "Базовый курс",
  "slug": "bazovyi-kurs",
  "description": "Введение в метод Бронникова. Основы развития сверхспособностей.",
  "price": "15.000,00 ₽",
  "price_kopecks": 1500000,
  "product_type": "course",
  "status": "published",
  "featured": true,
  "category": "Курсы"
}
```

## Корзина

### GET /cart
Получение содержимого корзины.

**Response (200 OK):**
```json
{
  "items": [
    {
      "product_id": 1,
      "name": "Базовый курс",
      "price": "15.000,00 ₽",
      "quantity": 1,
      "subtotal": "15.000,00 ₽"
    }
  ],
  "total_price": "15.000,00 ₽",
  "count": 1
}
```

### POST /cart/add_item
Добавление товара в корзину.

**Request:**
```json
{
  "product_id": 1,
  "quantity": 1
}
```

**Response (200 OK):**
```json
{
  "message": "Товар добавлен в корзину",
  "count": 1
}
```

### DELETE /cart/remove_item/:product_id
Удаление товара из корзины.

**Response (200 OK):**
```json
{
  "message": "Товар удален из корзины",
  "count": 0
}
```

### PATCH /cart
Обновление количества товара в корзине.

**Request:**
```json
{
  "product_id": 1,
  "quantity": 2
}
```

**Response (200 OK):**
```json
{
  "message": "Корзина обновлена",
  "count": 2
}
```

### DELETE /cart
Очистка корзины.

**Response (200 OK):**
```json
{
  "message": "Корзина очищена"
}
```

## Заказы

### GET /orders
Получение списка заказов текущего пользователя.

**Headers:**
```
Authorization: Bearer YOUR_JWT_TOKEN
```

**Response (200 OK):**
```json
[
  {
    "id": 1,
    "order_number": "ORD-1769972084-E01C0E35",
    "total": "1.500,00 ₽",
    "status": "paid",
    "payment_method": "wallet",
    "paid_at": "2026-02-01T18:50:00.000Z",
    "created_at": "2026-02-01T18:50:00.000Z",
    "items": [
      {
        "product_name": "Базовый курс",
        "price": "15.000,00 ₽",
        "quantity": 1,
        "subtotal": "15.000,00 ₽"
      }
    ]
  }
]
```

### GET /orders/:id
Получение информации о заказе.

**Response (200 OK):**
```json
{
  "id": 1,
  "order_number": "ORD-1769972084-E01C0E35",
  "total": "1.500,00 ₽",
  "status": "paid",
  "payment_method": "wallet",
  "paid_at": "2026-02-01T18:50:00.000Z",
  "created_at": "2026-02-01T18:50:00.000Z",
  "items": [
    {
      "product_name": "Базовый курс",
      "price": "15.000,00 ₽",
      "quantity": 1,
      "subtotal": "15.000,00 ₽"
    }
  ]
}
```

### POST /orders
Создание заказа из корзины.

**Headers:**
```
Authorization: Bearer YOUR_JWT_TOKEN
```

**Request:**
```json
{
  "payment_method": "wallet"
}
```

или

```json
{
  "payment_method": "cloudpayments"
}
```

**Response (201 Created) - для wallet:**
```json
{
  "message": "Заказ оплачен из кошелька",
  "order": {
    "id": 1,
    "order_number": "ORD-1769972084-E01C0E35",
    "total": "1.500,00 ₽",
    "status": "paid",
    "payment_method": "wallet",
    "paid_at": "2026-02-01T18:50:00.000Z",
    "created_at": "2026-02-01T18:50:00.000Z",
    "items": [...]
  }
}
```

**Response (201 Created) - для cloudpayments:**
```json
{
  "message": "Заказ создан",
  "order": {
    "id": 1,
    "order_number": "ORD-1769972084-E01C0E35",
    "total": "1.500,00 ₽",
    "status": "pending",
    "payment_method": "cloudpayments",
    "paid_at": null,
    "created_at": "2026-02-01T18:50:00.000Z",
    "items": [...]
  },
  "redirect_to": "/orders/1/payment"
}
```

**Response (422 Unprocessable Entity) - недостаточно средств:**
```json
{
  "error": "Недостаточно средств в кошельке"
}
```

## Webhooks

### POST /webhooks/cloudpayments/pay
Webhook для уведомления об успешной оплате через CloudPayments.

**Request:**
```json
{
  "InvoiceId": "ORD-1769972084-E01C0E35",
  "TransactionId": "12345678",
  "Amount": 15000.00,
  "Currency": "RUB"
}
```

**Response (200 OK):**
```json
{
  "code": 0
}
```

### POST /webhooks/cloudpayments/fail
Webhook для уведомления о неуспешной оплате.

**Request:**
```json
{
  "InvoiceId": "ORD-1769972084-E01C0E35",
  "Reason": "InsufficientFunds"
}
```

**Response (200 OK):**
```json
{
  "code": 0
}
```

### POST /webhooks/cloudpayments/refund
Webhook для уведомления о возврате средств.

**Request:**
```json
{
  "InvoiceId": "ORD-1769972084-E01C0E35",
  "TransactionId": "12345678"
}
```

**Response (200 OK):**
```json
{
  "code": 0
}
```

## Коды состояния

- `200 OK` - успешный запрос
- `201 Created` - ресурс успешно создан
- `401 Unauthorized` - требуется аутентификация
- `403 Forbidden` - доступ запрещен
- `404 Not Found` - ресурс не найден
- `422 Unprocessable Entity` - ошибка валидации

## Примеры использования

### Полный цикл покупки

1. **Получить список продуктов:**
```bash
curl http://localhost:3000/products
```

2. **Добавить продукт в корзину:**
```bash
curl -X POST http://localhost:3000/cart/add_item \
  -H "Content-Type: application/json" \
  -d '{"product_id": 1, "quantity": 1}'
```

3. **Войти в систему:**
```bash
curl -X POST http://localhost:3000/api/v1/login \
  -H "Content-Type: application/json" \
  -d '{"email":"client@example.com","password":"password123"}'
```

4. **Создать заказ:**
```bash
curl -X POST http://localhost:3000/orders \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{"payment_method":"wallet"}'
```

5. **Проверить доступ к продукту:**
```bash
curl http://localhost:3000/api/v1/users/YOUR_USER_ID \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

## State Machines

### Product States
- `draft` → `published` (event: `publish`)
- `draft` → `archived` (event: `archive`)
- `published` → `archived` (event: `archive`)
- `archived` → `draft` (event: `unarchive`)

### Order States
- `pending` → `processing` (event: `process`)
- `pending` → `paid` (event: `pay`)
- `processing` → `paid` (event: `pay`)
- `paid` → `completed` (event: `complete`)
- `pending` → `failed` (event: `fail`)
- `processing` → `failed` (event: `fail`)
- `paid` → `refunded` (event: `refund`)
- `completed` → `refunded` (event: `refund`)

**Заметка:** При переходе в состояние `paid` автоматически создается `ProductAccess` для пользователя. При `refund` доступ отзывается.
