# Деплой Sistema Bronnikova через Coolify

## Подготовка проекта

### 1. Проверка версий
Убедитесь, что версии в проекте соответствуют Dockerfile:
- Ruby: 3.3.8 (проверьте `.ruby-version`)
- Rails: 8.1.2

### 2. Credentials и секреты
Подготовьте следующие переменные окружения:

```bash
# Обязательные
RAILS_MASTER_KEY=<значение из config/master.key>
SECRET_KEY_BASE=<сгенерировать через rails secret>
DATABASE_URL=postgresql://user:password@host:5432/sbf_production

# Redis (для Solid Queue, Solid Cache, Solid Cable)
REDIS_URL=redis://redis:6379/0

# Опциональные - интеграции
TELEGRAM_BOT_TOKEN=<ваш токен>
CLOUDPAYMENTS_PUBLIC_ID=<ваш public_id>
CLOUDPAYMENTS_API_SECRET=<ваш api_secret>
SMTP_ADDRESS=<smtp сервер>
SMTP_PORT=587
SMTP_USERNAME=<smtp логин>
SMTP_PASSWORD=<smtp пароль>
GOOGLE_ANALYTICS_MEASUREMENT_ID=<ваш GA4 id>
```

## Деплой через Coolify

### Шаг 1: Создание приложения в Coolify

1. Войдите в Coolify Dashboard
2. Создайте новое приложение: **+ New Resource** → **Docker**
3. Выберите источник: **GitHub Repository**
4. Укажите репозиторий: `https://github.com/ваш-username/sbf`
5. Ветка: `main` (или ваша production ветка)

### Шаг 2: Настройка Docker

**Build Settings:**
- Dockerfile Location: `./Dockerfile`
- Build Context: `/`
- Port Mapping: `80:80`

**Health Check:**
- Path: `/up`
- Interval: 30s
- Timeout: 5s
- Retries: 3

### Шаг 3: Настройка Environment Variables

Добавьте все переменные окружения из раздела "Credentials и секреты":

```env
RAILS_ENV=production
RAILS_MASTER_KEY=your_master_key_here
SECRET_KEY_BASE=your_secret_key_base_here
DATABASE_URL=postgresql://user:pass@db:5432/sbf_production
REDIS_URL=redis://redis:6379/0
RAILS_SERVE_STATIC_FILES=true
RAILS_LOG_TO_STDOUT=true
```

### Шаг 4: Настройка PostgreSQL

**Вариант A: Использовать PostgreSQL из Coolify**
1. В Coolify: **+ New Resource** → **PostgreSQL 14**
2. После создания, скопируйте `DATABASE_URL`
3. Добавьте в Environment Variables приложения

**Вариант B: Внешняя PostgreSQL**
```env
DATABASE_URL=postgresql://username:password@external-host:5432/sbf_production
```

### Шаг 5: Настройка Redis

**Вариант A: Использовать Redis из Coolify**
1. В Coolify: **+ New Resource** → **Redis 7**
2. После создания, скопируйте `REDIS_URL`
3. Добавьте в Environment Variables приложения

**Вариант B: Внешний Redis**
```env
REDIS_URL=redis://external-host:6379/0
```

### Шаг 6: Настройка persistent storage

Для хранения uploaded файлов создайте volume:
1. В настройках приложения: **Storages** → **+ Add Storage**
2. Name: `storage`
3. Mount Path: `/rails/storage`
4. Source Path: `/var/lib/coolify/storage/sbf-storage`

### Шаг 7: Deploy

1. Нажмите **Deploy** в правом верхнем углу
2. Следите за логами сборки
3. После успешной сборки приложение будет доступно по URL

### Шаг 8: Первый запуск - миграции

После первого деплоя нужно запустить миграции:

1. Откройте **Terminal** в Coolify для вашего приложения
2. Выполните:
```bash
bundle exec rails db:create
bundle exec rails db:migrate
bundle exec rails db:seed  # опционально - загрузить demo данные
```

## Проверка работоспособности

После деплоя проверьте:

1. **Health Check**: `https://your-domain.com/up` - должен вернуть статус 200
2. **Главная страница**: `https://your-domain.com/` - должна загрузиться
3. **Админка**: `https://your-domain.com/admin` - должна быть доступна
4. **Логи**: В Coolify проверьте логи на отсутствие ошибок

## Настройка домена

1. В Coolify: **Domains** → **+ Add Domain**
2. Укажите ваш домен: `sistema-bronnikova.ru`
3. Настройте DNS записи (A или CNAME) на IP сервера Coolify
4. Coolify автоматически выпустит SSL сертификат через Let's Encrypt

## Troubleshooting

### Ошибка: "Asset not found"
Убедитесь что assets прекомпилированы:
```bash
SECRET_KEY_BASE_DUMMY=1 bundle exec rails assets:precompile
```

### Ошибка: "Database connection failed"
Проверьте `DATABASE_URL`:
```bash
# В терминале контейнера
bundle exec rails db:migrate:status
```

### Ошибка: "Redis connection failed"
Проверьте `REDIS_URL` и доступность Redis:
```bash
# В терминале контейнера
bundle exec rails runner "puts Redis.new(url: ENV['REDIS_URL']).ping"
```

### Slow queries
Rails 8 использует Solid Queue, Solid Cache и Solid Cable на базе PostgreSQL.
Для оптимизации добавьте индексы:
```bash
bundle exec rails db:migrate
```

## Continuous Deployment

Coolify автоматически деплоит при push в main ветку, если включен **Auto Deploy**:

1. В настройках приложения: **Build** → **Auto Deploy**
2. Включите **Deploy on Push**
3. Webhook автоматически настроится в GitHub

Теперь каждый push в `main` будет автоматически деплоиться!

## Backup

### PostgreSQL Backup
Рекомендуется настроить автоматические бэкапы БД:
```bash
# Ручной backup
pg_dump $DATABASE_URL > backup_$(date +%Y%m%d).sql

# Восстановление
psql $DATABASE_URL < backup_20260204.sql
```

### Storage Backup
Файлы в `/rails/storage` нужно бэкапить отдельно.

## Мониторинг

- **Логи**: В Coolify → Logs
- **Metrics**: В Coolify → Metrics (CPU, Memory, Network)
- **Health**: Автоматический health check на `/up`

## Масштабирование

Для увеличения производительности:

1. **Vertical Scaling**: Увеличьте ресурсы контейнера в Coolify
2. **Horizontal Scaling**: Добавьте больше инстансов приложения
3. **Database**: Используйте managed PostgreSQL (например, от Hetzner или DigitalOcean)
4. **Redis**: Используйте managed Redis для production

## Полезные команды

```bash
# Rails console в production
bundle exec rails console

# Проверить статус задач
bundle exec rails solid_queue:status

# Очистить кэш
bundle exec rails cache:clear

# Проверить настройки
bundle exec rails about
```

## Support

Если возникли проблемы:
1. Проверьте логи в Coolify
2. Проверьте health check endpoint: `/up`
3. Проверьте переменные окружения
4. Откройте issue в репозитории проекта
