# Telegram Bot Setup Guide

## 📋 Обзор

Telegram Bot обеспечивает быстрый доступ к функциям платформы "Система Бронникова" через мессенджер Telegram.

**Возможности:**
- 💰 Проверка баланса кошелька
- 📦 Просмотр последних заказов
- 🎓 Список активных курсов
- 🔗 Привязка Telegram к аккаунту
- ℹ️ Справка по командам

---

## 🤖 Creating Telegram Bot

### Step 1: Create Bot via BotFather

1. **Open Telegram** и найдите **@BotFather**
2. **Send command**: `/newbot`
3. **Choose bot name**: `Bronnikov Platform Bot`
4. **Choose username**: `bronnikov_platform_bot` (должен заканчиваться на `bot`)
5. **Save bot token**: `123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11`

### Step 2: Configure Bot Settings

**Set description:**
```
/setdescription @bronnikov_platform_bot
```
```
Бот-помощник платформы "Система Бронникова".
Проверяйте баланс, заказы и курсы прямо в Telegram!
```

**Set about text:**
```
/setabouttext @bronnikov_platform_bot
```
```
Официальный бот платформы Бронникова
```

**Set commands:**
```
/setcommands @bronnikov_platform_bot
```
```
start - Начать работу
link - Привязать Telegram к аккаунту
balance - Баланс кошелька
orders - Последние заказы
courses - Мои курсы
help - Помощь
```

---

## ⚙️ Rails Configuration

### 1. Add Bot Token to Credentials

```bash
EDITOR="nano" rails credentials:edit
```

Add:
```yaml
telegram:
  bot_token: 123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11
```

### 2. Set Environment Variables

```bash
# .env or production environment
APP_URL=https://platform.bronnikov.com
```

### 3. Run Database Migration

```bash
rails db:migrate
```

This adds `telegram_chat_id` column to `users` table.

### 4. Setup Webhook

```bash
rails telegram:setup_webhook
```

**Output:**
```
🤖 Setting up Telegram webhook...
Webhook URL: https://platform.bronnikov.com/webhooks/telegram/123456:ABC...
✅ Webhook set successfully!
```

---

## 🧪 Testing

### Test Bot Connection

```bash
rails telegram:test
```

**Output:**
```
✅ Bot connected successfully!

Bot info:
  Username: @bronnikov_platform_bot
  First name: Bronnikov Platform Bot
  ID: 123456789
```

### Manual Testing

**1. Find bot in Telegram:**
- Search: `@bronnikov_platform_bot`
- Click "Start"

**2. Test commands:**
```
/start    - Should show welcome message
/link     - Should send linking URL
/help     - Should show commands list
```

**3. Link Telegram to account:**
- Send `/link` in bot
- Copy link URL
- Open in browser (while logged in)
- Should see: "Telegram успешно привязан!"
- Bot should send confirmation message

**4. Test authenticated commands:**
```
/balance  - Should show wallet balance
/orders   - Should show last 5 orders
/courses  - Should show active courses
```

---

## 🔗 User Linking Flow

### Diagram

```
┌─────────────────────────────────────────────────────────┐
│ 1. User sends /link command in Telegram                │
│    Bot generates unique token (32 chars)                │
│    Token stored in Rails.cache (10 min expiry)         │
│    Bot sends link: /telegram/link/{token}              │
└─────────────────────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│ 2. User clicks link (must be logged into platform)     │
│    Opens in browser                                      │
│    TelegramController#link processes request            │
└─────────────────────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│ 3. Controller validates token (from cache)              │
│    Updates user: telegram_chat_id = chat_id            │
│    Deletes token from cache                             │
│    Sends confirmation to Telegram                       │
└─────────────────────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│ 4. User receives confirmation in Telegram              │
│    "✅ Telegram успешно привязан!"                      │
│    Can now use: /balance, /orders, /courses            │
└─────────────────────────────────────────────────────────┘
```

---

## 📱 Bot Commands

### `/start` - Welcome message

```
👋 Добро пожаловать в Систему Бронникова!

Я бот-помощник платформы.

Доступные команды:
/link - Привязать Telegram к аккаунту
/balance - Баланс кошелька
/orders - Последние заказы
/courses - Мои курсы
/help - Помощь
```

### `/link` - Get linking URL

```
🔗 Привязка Telegram аккаунта

Перейдите по ссылке для привязки:
https://platform.bronnikov.com/telegram/link/abc123...

⏰ Ссылка действительна 10 минут.
```

**Requirements:**
- User must be logged into platform
- Link expires in 10 minutes
- Token can only be used once

### `/balance` - Check wallet balance

```
💰 Баланс кошелька

Текущий баланс: 5 000 ₽

Для пополнения перейдите в личный кабинет:
https://platform.bronnikov.com/dashboard/wallet
```

**Requirements:**
- Telegram must be linked to account

### `/orders` - View recent orders

```
📦 Последние заказы:

✅ ORD-1234-ABCD
Сумма: 3 000 ₽
Статус: Оплачен
Дата: 01.02.2026

⏳ ORD-1235-EFGH
Сумма: 1 500 ₽
Статус: Ожидает оплаты
Дата: 03.02.2026

Подробнее в личном кабинете:
https://platform.bronnikov.com/dashboard/orders
```

**Limits:** Last 5 orders

### `/courses` - View active courses

```
🎓 Мои курсы:

🎓 Базовый курс Бронникова
Тип: Курс
Доступ с: 15.01.2026

📚 Книга "Информационное развитие"
Тип: Книга
Доступ с: 20.01.2026

Все курсы в личном кабинете:
https://platform.bronnikov.com/dashboard/my-courses
```

**Limits:** 10 most recent courses

### `/help` - Show help

```
ℹ️ Помощь

Доступные команды:
/start - Начать работу
/link - Привязать Telegram к аккаунту
/balance - Проверить баланс кошелька
/orders - Последние заказы
/courses - Мои курсы
/help - Показать эту справку

Поддержка:
Email: support@bronnikov.com
Сайт: https://bronnikov.com
```

---

## 🏗️ Architecture

### Controllers

**Webhooks::TelegramController** (`app/controllers/webhooks/telegram_controller.rb`)
- `webhook` - Main webhook handler
- `handle_start` - /start command
- `handle_link` - /link command
- `handle_balance` - /balance command
- `handle_orders` - /orders command
- `handle_courses` - /courses command
- `handle_help` - /help command
- `handle_unknown` - Unknown commands

**TelegramController** (`app/controllers/telegram_controller.rb`)
- `link` - Process linking from web

### Service

**TelegramBotService** (`app/services/telegram_bot_service.rb`)
- `send_message(chat_id, text, options)` - Send message to user
- `set_webhook(url)` - Setup Telegram webhook
- `delete_webhook` - Remove webhook
- `format_currency(kopecks)` - Format money
- `format_date(date)` - Format date

### Database

**Migration:** `AddTelegramChatIdToUsers`
```ruby
add_column :users, :telegram_chat_id, :bigint
add_index :users, :telegram_chat_id, unique: true
```

**User Model:**
- `telegram_chat_id` - Telegram chat ID (bigint, unique)

### Routes

```ruby
# Webhook endpoint
post 'webhooks/telegram/:token', to: 'webhooks/telegram#webhook'

# Linking endpoint
get 'telegram/link/:token', to: 'telegram#link'
```

---

## 🔒 Security

### Bot Token Protection

- ✅ Stored in encrypted credentials (not in code)
- ✅ Webhook URL includes token (authenticates Telegram)
- ✅ Token never exposed in responses

### Linking Security

- ✅ Unique 32-character tokens (SecureRandom)
- ✅ 10-minute expiration (Rails.cache)
- ✅ Single-use tokens (deleted after use)
- ✅ Requires user to be logged in
- ✅ User must initiate link from Telegram

### Data Security

- ✅ telegram_chat_id stored securely in database
- ✅ Unique index prevents duplicates
- ✅ Only linked users can access data
- ✅ Webhook validates Telegram origin

---

## 🐛 Troubleshooting

### Issue: "Webhook setup failed"

**Possible causes:**
- Invalid bot token
- APP_URL not set
- URL not reachable from internet
- HTTPS not configured (required for webhooks)

**Solutions:**
```bash
# 1. Test bot token:
rails telegram:test

# 2. Check APP_URL:
echo $APP_URL  # Should be https://...

# 3. Test URL accessibility:
curl https://platform.bronnikov.com/up

# 4. Check credentials:
rails credentials:show
```

### Issue: "Bot not responding to commands"

**Check:**
1. **Webhook set?** `rails telegram:setup_webhook`
2. **Token correct?** `rails credentials:show | grep telegram`
3. **Rails server running?** Production server must be up
4. **Logs:** Check `log/production.log` for errors

**Debug:**
```bash
# Check webhook status:
curl "https://api.telegram.org/bot{TOKEN}/getWebhookInfo"

# Should show:
# "url": "https://platform.bronnikov.com/webhooks/telegram/{TOKEN}"
# "pending_update_count": 0
```

### Issue: "Commands return 'not linked' message"

**Check:**
1. **User linked?** Send `/link` and complete linking
2. **chat_id saved?** Rails console: `User.find_by(email: '...').telegram_chat_id`
3. **Cache cleared?** Linking token might be expired

**Solution:**
```ruby
# Rails console:
user = User.find_by(email: 'your@email.com')
user.update(telegram_chat_id: YOUR_CHAT_ID)  # Get from Telegram /start
```

### Issue: "Linking URL expired"

**Reason:** Token expires in 10 minutes

**Solution:**
- Send `/link` again in bot
- Get new URL
- Complete linking within 10 minutes

---

## 📊 Statistics & Monitoring

### User Linking Stats

```ruby
# Rails console
User.where.not(telegram_chat_id: nil).count  # Linked users
User.where(telegram_chat_id: nil).count      # Not linked

# Linking rate:
linked = User.where.not(telegram_chat_id: nil).count.to_f
total = User.count.to_f
rate = (linked / total * 100).round(2)
puts "#{rate}% users linked"
```

### Bot Usage Logs

Check `log/production.log` for:
- `/start` commands (new users)
- `/balance` requests (engagement)
- `/orders` requests
- `/courses` requests
- Error messages

**Example log entry:**
```
[Telegram] Command: /balance, Chat ID: 123456789, User: user@example.com
```

---

## 🚀 Production Deployment

### Checklist

- [ ] **Bot created** via @BotFather
- [ ] **Commands set** in BotFather
- [ ] **Token added** to credentials
- [ ] **APP_URL set** in environment
- [ ] **Migration run**: `rails db:migrate`
- [ ] **Webhook set**: `rails telegram:setup_webhook`
- [ ] **Connection tested**: `rails telegram:test`
- [ ] **Manual test**: Send /start to bot
- [ ] **Linking tested**: Complete /link flow
- [ ] **Commands tested**: /balance, /orders, /courses

### Rake Tasks Reference

```bash
# Setup webhook (run after deploy)
rails telegram:setup_webhook

# Delete webhook (for maintenance)
rails telegram:delete_webhook

# Test bot connection
rails telegram:test
```

---

## 📈 Future Enhancements

**Potential features:**
- Push notifications (new orders, course updates)
- Inline keyboard buttons (quick actions)
- Payment via Telegram (CloudPayments integration)
- Course progress tracking
- Achievement notifications
- Support chat integration
- Multi-language support

**Implementation priority:**
1. Push notifications (HIGH)
2. Inline keyboards (MEDIUM)
3. Payment integration (LOW - requires Telegram Payments API)

---

## 📞 Support

**Bot Issues:**
- Check logs: `tail -f log/production.log | grep Telegram`
- Test connection: `rails telegram:test`
- Verify webhook: `rails telegram:setup_webhook`

**Telegram API:**
- Documentation: https://core.telegram.org/bots/api
- Bot updates: https://core.telegram.org/bots
- BotFather: @BotFather in Telegram

**Platform Support:**
- Email: support@bronnikov.com
- Telegram: @bronnikov_support
- Docs: https://platform.bronnikov.com/docs

---

**Last Updated:** 2026-02-04
**Bot Version:** 1.0.0
**API:** Telegram Bot API 7.0+
