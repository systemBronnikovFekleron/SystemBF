=== Bronnikov SSO ===
Contributors: bronnikov
Tags: sso, single sign-on, authentication, jwt, bronnikov
Requires at least: 5.8
Tested up to: 6.4
Requires PHP: 7.4
Stable tag: 1.0.0
License: GPLv2 or later
License URI: https://www.gnu.org/licenses/gpl-2.0.html

Single Sign-On интеграция с платформой "Система Бронникова"

== Description ==

Bronnikov SSO обеспечивает бесшовную интеграцию между вашим WordPress сайтом и платформой "Система Бронникова". Пользователи, авторизованные на платформе, автоматически получают доступ к WordPress с соответствующими правами.

= Основные возможности =

* **Автоматический вход** - Пользователи платформы автоматически авторизуются в WordPress
* **Синхронизация данных** - Имя, фамилия и роль синхронизируются с платформы
* **Маппинг ролей** - Классификация пользователей платформы автоматически преобразуется в роли WordPress
* **Безопасность** - JWT токен валидируется через защищенный API endpoint
* **Простая настройка** - Всего два параметра для подключения

= Маппинг ролей =

* Admin, Manager, Curator → Administrator/Editor
* Center Director → Editor
* Specialist, Expert, Instructors → Contributor
* Representative → Author
* Client, Guest → Subscriber

= Требования =

* WordPress 5.8 или выше
* PHP 7.4 или выше
* Активная подписка на платформе "Система Бронникова"

== Installation ==

1. Загрузите папку `bronnikov-sso` в директорию `/wp-content/plugins/`
2. Активируйте плагин через меню 'Plugins' в WordPress
3. Перейдите в Settings → Bronnikov SSO
4. Введите URL вашей платформы (например, `https://platform.bronnikov.com`)
5. Включите SSO checkbox
6. Сохраните настройки
7. Нажмите "Test Connection" для проверки подключения

== Frequently Asked Questions ==

= Как работает автоматический вход? =

Когда пользователь авторизован на платформе Bronnikov, в его браузере сохраняется JWT токен в cookie. При посещении WordPress сайта, плагин проверяет наличие токена, валидирует его через API платформы и автоматически авторизует пользователя.

= Что если пользователь еще не зарегистрирован в WordPress? =

Плагин автоматически создаст нового пользователя WordPress на основе данных с платформы. Email, имя и фамилия будут синхронизированы, а роль назначена согласно маппингу.

= Можно ли изменить маппинг ролей? =

В текущей версии маппинг ролей жестко задан в коде. Если вам нужен кастомный маппинг, вы можете отредактировать файл `includes/class-auth.php` и изменить массив в методе `map_classification_to_role()`.

= Безопасен ли этот плагин? =

Да. Плагин использует JWT токены с ограниченным сроком действия (24 часа), валидирует их через защищенный API endpoint, и следует всем best practices WordPress для создания и управления пользователями.

= Что делать если connection test не проходит? =

Убедитесь что:
1. URL платформы указан корректно (с https://)
2. Платформа доступна из вашего WordPress сервера
3. На платформе включена поддержка CORS для вашего домена

== Changelog ==

= 1.0.0 =
* Initial release
* Auto-login functionality
* User synchronization
* Role mapping
* Admin settings page
* Connection testing

== Upgrade Notice ==

= 1.0.0 =
Initial release of Bronnikov SSO plugin.

== Screenshots ==

1. Settings page - Configure API URL and enable SSO
2. Role mapping table - See how platform roles map to WordPress roles
3. Test connection - Verify your platform connection

== Support ==

Для поддержки и документации посетите:
* Platform Documentation: https://platform.bronnikov.com/docs
* SSO Integration Guide: https://platform.bronnikov.com/docs/sso
* GitHub: https://github.com/bronnikov/platform

== Privacy Policy ==

Этот плагин взаимодействует с внешним сервисом - платформой "Система Бронникова":
* API endpoint: https://platform.bronnikov.com/api/v1/validate_token
* Передаваемые данные: JWT токен из cookie пользователя
* Получаемые данные: Email, имя, фамилия, классификация пользователя
* Цель: Валидация токена и синхронизация данных пользователя

Политика конфиденциальности платформы: https://bronnikov.com/privacy
