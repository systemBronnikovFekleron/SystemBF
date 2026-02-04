# WordPress SSO Plugin - Installation & Setup Guide

## 📋 Обзор

WordPress SSO плагин обеспечивает Single Sign-On интеграцию между WordPress сайтами и платформой "Система Бронникова".

**Как работает:**
1. Пользователь авторизуется на платформе (platform.bronnikov.com)
2. JWT токен сохраняется в browser cookie
3. При посещении WordPress сайта, плагин читает токен
4. Токен валидируется через API endpoint `/api/v1/validate_token`
5. Пользователь автоматически авторизуется в WordPress

---

## 🎯 Features

### ✅ Auto-Login
- Автоматическая авторизация пользователей с valid JWT token
- Работает на каждом page load (hook: `init` priority 1)
- Не требует действий от пользователя

### ✅ User Synchronization
- Автоматическое создание WordPress users
- Синхронизация email, first_name, last_name
- Сохранение Bronnikov user_id в meta
- Last sync timestamp

### ✅ Role Mapping
- Автоматический маппинг classification → WordPress role
- 14 classifications платформы → 5 WordPress roles
- Обновление role при каждом login

### ✅ Admin Settings
- Простая настройка через Settings → Bronnikov SSO
- API URL configuration
- Enable/Disable toggle
- Connection test button

---

## 📦 Installation

### Step 1: Install Plugin

**Option A: Manual Installation**
```bash
# На вашем WordPress сервере:
cd /path/to/wordpress/wp-content/plugins/

# Скопируйте плагин:
scp -r /path/to/bronnikov-sso ./

# Или через FTP: загрузите папку bronnikov-sso в wp-content/plugins/
```

**Option B: ZIP Upload**
```bash
# Создайте ZIP архив:
cd /path/to/wordpress-plugin/
zip -r bronnikov-sso.zip bronnikov-sso/

# В WordPress Admin:
# 1. Plugins → Add New → Upload Plugin
# 2. Choose bronnikov-sso.zip
# 3. Install Now
```

### Step 2: Activate Plugin

1. Go to **Plugins** in WordPress admin
2. Find **Bronnikov SSO**
3. Click **Activate**

### Step 3: Configure Settings

1. Go to **Settings → Bronnikov SSO**
2. Enter **Platform API URL**: `https://platform.bronnikov.com`
3. Check **Enable SSO** checkbox
4. Click **Save Changes**

### Step 4: Test Connection

1. Click **Test Connection** button
2. Should see: "✓ Connection successful! Platform is reachable."
3. If error, check API URL and network connectivity

---

## ⚙️ Configuration

### Rails Platform Configuration

**1. Add CORS headers** (уже реализовано в Phase D1):

File: `app/controllers/api/v1/authentication_controller.rb`
```ruby
before_action :set_cors_headers, only: [:validate_token]

private

def set_cors_headers
  wordpress_domain = ENV.fetch('WORDPRESS_DOMAIN', '*')
  response.headers['Access-Control-Allow-Origin'] = wordpress_domain
  response.headers['Access-Control-Allow-Credentials'] = 'true'
  response.headers['Access-Control-Allow-Methods'] = 'GET, OPTIONS'
  response.headers['Access-Control-Allow-Headers'] = 'Authorization, Content-Type'
end
```

**2. Set environment variable:**

```bash
# .env или production environment
WORDPRESS_DOMAIN=https://blog.bronnikov.com

# Для multiple WordPress sites (не рекомендуется):
WORDPRESS_DOMAIN=*
```

**3. Cookie configuration:**

Cookie `jwt_token` должен быть:
- ✅ `httpOnly: true` (защита от XSS)
- ✅ `secure: true` (production only, HTTPS)
- ✅ `same_site: :lax` (разрешает cross-site cookies)
- ✅ `domain: .bronnikov.com` (shared между subdomains)

**Правильная настройка** (уже в коде):
```ruby
cookies.encrypted[:jwt_token] = {
  value: token,
  expires: 24.hours.from_now,
  httponly: true,
  secure: Rails.env.production?,
  same_site: :lax,
  domain: '.bronnikov.com'  # Shared cookie
}
```

### WordPress Plugin Configuration

**Settings Page** (Settings → Bronnikov SSO):

| Setting | Description | Example |
|---------|-------------|---------|
| **Platform API URL** | Base URL платформы | `https://platform.bronnikov.com` |
| **Enable SSO** | Включить/выключить auto-login | ☑️ Checked |

---

## 👥 Role Mapping

WordPress плагин автоматически преобразует classification пользователя в WordPress role:

| Platform Classification | WordPress Role | Capabilities |
|------------------------|----------------|--------------|
| `admin` | Administrator | Full control |
| `manager` | Editor | Publish & manage posts |
| `curator` | Editor | Publish & manage posts |
| `center_director` | Editor | Publish & manage posts |
| `specialist` | Contributor | Write posts (require approval) |
| `expert` | Contributor | Write posts (require approval) |
| `instructor_1`, `instructor_2`, `instructor_3` | Contributor | Write posts |
| `representative` | Author | Publish own posts |
| `trainee` | Subscriber | Read only |
| `club_member` | Subscriber | Read only |
| `client` | Subscriber | Read only |
| `guest` | Subscriber | Read only |

**Custom Role Mapping:**

Если нужен другой маппинг, отредактируйте:

File: `wp-content/plugins/bronnikov-sso/includes/class-auth.php`

Method: `map_classification_to_role()`

```php
private static function map_classification_to_role( $classification ) {
    $mapping = array(
        'admin' => 'administrator',
        // ... ваш кастомный маппинг
    );
    return isset( $mapping[ $classification ] ) ? $mapping[ $classification ] : 'subscriber';
}
```

---

## 🔐 Security

### JWT Token Security

**Token Properties:**
- 24-hour expiration
- Signed with `SECRET_KEY_BASE`
- Encrypted cookie storage
- HTTPS-only in production

**Validation Process:**
1. Plugin reads `jwt_token` cookie
2. Sends token to `/api/v1/validate_token` via Authorization header
3. Rails validates signature and expiration
4. Returns user data or 401 Unauthorized

### WordPress Security

**User Creation:**
- Random 32-character password
- Password never shared with user
- User cannot login with password (only via SSO)

**Data Sanitization:**
- All input sanitized: `sanitize_email()`, `sanitize_text_field()`
- Output escaped: `esc_html()`, `esc_attr()`, `esc_url()`
- Nonces used for admin actions

### Best Practices

**✅ DO:**
- Use HTTPS for both platform and WordPress
- Set specific `WORDPRESS_DOMAIN` (not `*`)
- Keep plugin updated
- Monitor WordPress user creation logs

**❌ DON'T:**
- Use HTTP in production
- Share credentials publicly
- Allow open CORS (`*`) in production
- Modify core plugin files (use hooks instead)

---

## 🧪 Testing

### Manual Testing Workflow

**1. Setup Test Environment:**
```bash
# Local WordPress (Docker):
docker run -d -p 8080:80 \
  -e WORDPRESS_DB_HOST=mysql \
  -e WORDPRESS_DB_USER=wp_user \
  -e WORDPRESS_DB_PASSWORD=password \
  -e WORDPRESS_DB_NAME=wordpress \
  --name wp-test \
  wordpress:latest
```

**2. Install Plugin:**
- Upload `bronnikov-sso` folder to `wp-content/plugins/`
- Activate via Plugins menu

**3. Configure Platform:**
```bash
# Rails console:
rails c

# Set cookie domain:
ENV['WORDPRESS_DOMAIN'] = 'http://localhost:8080'
```

**4. Test Auto-Login:**
```bash
# 1. Login to platform (http://localhost:3000/login)
# 2. Check cookie exists:
#    DevTools → Application → Cookies → jwt_token
# 3. Visit WordPress (http://localhost:8080)
# 4. Should be auto-logged in!
```

**5. Verify User:**
- WordPress Admin → Users
- Find newly created user
- Check role matches classification
- Check user meta: `bronnikov_user_id`, `bronnikov_classification`

### Test Cases

**✅ Positive Tests:**
- [ ] Auto-login works with valid JWT
- [ ] User created if not exists
- [ ] User role matches classification
- [ ] User data synced (name, email)
- [ ] Connection test passes

**❌ Negative Tests:**
- [ ] No auto-login without JWT cookie
- [ ] Invalid JWT rejected
- [ ] Expired JWT (> 24h) rejected
- [ ] Wrong API URL shows error
- [ ] Disabled SSO prevents auto-login

---

## 🐛 Troubleshooting

### Issue: "Connection failed" error

**Possible causes:**
- API URL incorrect
- Platform not running
- Firewall blocking requests
- SSL certificate issues

**Solutions:**
```bash
# 1. Test connectivity:
curl -I https://platform.bronnikov.com/up

# 2. Check WordPress error log:
tail -f /var/log/apache2/error.log  # or nginx

# 3. Check PHP error log:
tail -f /var/log/php/error.log

# 4. Enable WordPress debugging:
# wp-config.php:
define('WP_DEBUG', true);
define('WP_DEBUG_LOG', true);
```

### Issue: Auto-login not working

**Check:**
1. **SSO enabled?** Settings → Bronnikov SSO → Enable SSO ☑️
2. **JWT cookie exists?** DevTools → Application → Cookies → `jwt_token`
3. **Cookie domain correct?** Should be `.bronnikov.com` (with dot!)
4. **CORS headers?** Platform must allow WordPress domain

**Debug:**
```php
// Add to wp-content/plugins/bronnikov-sso/includes/class-auth.php
// In auto_login() method:
error_log('JWT Token: ' . print_r($_COOKIE['jwt_token'], true));
error_log('User Data: ' . print_r($user_data, true));
```

### Issue: User role incorrect

**Check role mapping:**
```php
// wp-content/plugins/bronnikov-sso/includes/class-auth.php
// Method: map_classification_to_role()

// Verify your classification:
error_log('Classification: ' . $classification);
error_log('Mapped Role: ' . $role);
```

### Issue: "Failed to create user" error

**Possible causes:**
- Email already exists (different username)
- Invalid email format
- WordPress user creation restrictions

**Solution:**
```bash
# Check WordPress error log for details
tail -f /path/to/wordpress/wp-content/debug.log
```

---

## 📁 Plugin File Structure

```
bronnikov-sso/
├── bronnikov-sso.php           # Main plugin file (66 lines)
│   ├── Plugin metadata
│   ├── Constants definition
│   ├── File includes
│   ├── Activation/deactivation hooks
│   └── Init action
│
├── includes/
│   ├── class-api.php           # API client (92 lines)
│   │   ├── validate_token()    # JWT validation
│   │   └── test_connection()   # Health check
│   │
│   ├── class-auth.php          # Authentication (175 lines)
│   │   ├── auto_login()        # Auto-login on init
│   │   ├── get_or_create_user()
│   │   ├── update_user_role()
│   │   ├── map_classification_to_role()
│   │   └── generate_username()
│   │
│   └── class-user-sync.php     # User sync (47 lines)
│       ├── sync_on_login()     # Sync on WP login
│       └── get_last_sync_time()
│
├── admin/
│   ├── class-settings.php      # Settings page (159 lines)
│   │   ├── add_settings_page()
│   │   ├── register_settings()
│   │   ├── render_settings_page()
│   │   └── enqueue_admin_styles()
│   │
│   └── views/
│       └── settings-page.php   # Settings template (87 lines)
│
├── assets/
│   └── css/
│       └── admin.css           # Admin styles (74 lines)
│
└── readme.txt                  # WordPress plugin readme (140 lines)
```

**Total:** 840+ lines of PHP code

---

## 🔄 User Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│ 1. User visits Platform (platform.bronnikov.com)           │
│    - Logs in with email/password                            │
│    - JWT token created (24h expiration)                     │
│    - Token saved in encrypted cookie: jwt_token             │
│    - Cookie domain: .bronnikov.com (shared)                 │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. User visits WordPress site (blog.bronnikov.com)         │
│    - WordPress loads                                         │
│    - Plugin hook: init (priority 1)                         │
│    - Plugin reads jwt_token cookie                          │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. Plugin validates token with Platform API                │
│    - GET /api/v1/validate_token                             │
│    - Authorization: Bearer {token}                          │
│    - Platform validates JWT signature                       │
│    - Returns: { valid: true, user: {...} }                 │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. Plugin creates/updates WordPress user                   │
│    - Find user by email                                      │
│    - If not exists: create new user                         │
│    - Update: first_name, last_name                          │
│    - Map classification → WordPress role                    │
│    - Save meta: bronnikov_user_id, classification           │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ 5. User is logged into WordPress                           │
│    - wp_set_current_user()                                  │
│    - wp_set_auth_cookie()                                   │
│    - wp_login action triggered                              │
│    - User sees WordPress content with appropriate role      │
└─────────────────────────────────────────────────────────────┘
```

---

## 📊 API Reference

### Platform Endpoint

**GET /api/v1/validate_token**

**Headers:**
```
Authorization: Bearer {jwt_token}
Content-Type: application/json
```

**Response (Success):**
```json
{
  "valid": true,
  "user": {
    "id": 123,
    "email": "user@example.com",
    "first_name": "Иван",
    "last_name": "Петров",
    "classification": "client",
    "active": true
  }
}
```

**Response (Failure):**
```json
{
  "valid": false
}
```

**Status Codes:**
- `200 OK` - Token valid or invalid (check `valid` field)
- `401 Unauthorized` - Token missing or malformed

---

## 🚀 Production Deployment

### Checklist

- [ ] **HTTPS enabled** on both platform and WordPress
- [ ] **WORDPRESS_DOMAIN** set in platform environment
- [ ] **Cookie domain** set to `.bronnikov.com`
- [ ] **Plugin activated** on WordPress
- [ ] **SSO enabled** in plugin settings
- [ ] **Connection test** passes
- [ ] **Test auto-login** with real user
- [ ] **Verify role mapping** for all classification types
- [ ] **Monitor error logs** for first 24 hours

### Performance Considerations

**Caching:**
- Plugin validates token on EVERY page load
- Consider caching validation result for 5-10 minutes
- Use WordPress transients: `set_transient()`, `get_transient()`

**Example optimization:**
```php
// In class-api.php validate_token()
$cache_key = 'bronnikov_token_' . md5($token);
$cached = get_transient($cache_key);
if ($cached !== false) {
    return $cached;
}

// ... validate token ...

set_transient($cache_key, $user_data, 5 * MINUTE_IN_SECONDS);
```

---

## 📞 Support

**Documentation:**
- Platform Docs: https://platform.bronnikov.com/docs
- SSO Integration: https://platform.bronnikov.com/docs/sso

**GitHub:**
- Repository: https://github.com/bronnikov/platform
- Issues: https://github.com/bronnikov/platform/issues

**Contact:**
- Email: support@bronnikov.com
- Telegram: @bronnikov_support

---

**Last Updated:** 2026-02-04
**Plugin Version:** 1.0.0
**Compatible With:** WordPress 5.8+, PHP 7.4+
