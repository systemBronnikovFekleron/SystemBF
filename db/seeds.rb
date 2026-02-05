# frozen_string_literal: true

# Очистка базы данных (только для development)
if Rails.env.development?
  puts "🗑️  Очистка базы данных..."
  # New models
  Favorite.destroy_all
  WikiPage.destroy_all
  Article.destroy_all
  EventRegistration.destroy_all
  Event.destroy_all
  Diagnostic.destroy_all
  Initiation.destroy_all
  # Integration data
  IntegrationStatistic.destroy_all
  IntegrationLog.destroy_all
  EmailTemplate.destroy_all
  IntegrationSetting.destroy_all
  # Shop data
  ProductAccess.destroy_all
  OrderItem.destroy_all
  Order.destroy_all
  Product.destroy_all
  Category.destroy_all
  # User data
  InteractionHistory.destroy_all
  Rating.destroy_all
  Wallet.destroy_all
  Profile.destroy_all
  User.destroy_all
end

puts "👥 Создание пользователей..."

# Администратор
admin = User.create!(
  email: 'admin@bronnikov.com',
  password: 'password123',
  password_confirmation: 'password123',
  first_name: 'Вячеслав',
  last_name: 'Бронников',
  classification: :admin
)
admin.wallet.deposit(1000000) # 10,000 руб
puts "  ✓ Администратор: #{admin.email}"

# Директор центра
director = User.create!(
  email: 'director@bronnikov.com',
  password: 'password123',
  password_confirmation: 'password123',
  first_name: 'Иван',
  last_name: 'Петров',
  classification: :center_director
)
director.wallet.deposit(500000) # 5,000 руб
puts "  ✓ Директор центра: #{director.email}"

# Специалист
specialist = User.create!(
  email: 'specialist@bronnikov.com',
  password: 'password123',
  password_confirmation: 'password123',
  first_name: 'Мария',
  last_name: 'Сидорова',
  classification: :specialist
)
specialist.wallet.deposit(300000) # 3,000 руб
specialist.rating.add_points(250) # уровень 3
puts "  ✓ Специалист: #{specialist.email}"

# Клиент
client = User.create!(
  email: 'client@example.com',
  password: 'password123',
  password_confirmation: 'password123',
  first_name: 'Алексей',
  last_name: 'Иванов',
  classification: :client
)
client.wallet.deposit(100000) # 1,000 руб
client.rating.add_points(50)
puts "  ✓ Клиент: #{client.email}"

# Гость
guest = User.create!(
  email: 'guest@example.com',
  password: 'password123',
  password_confirmation: 'password123',
  first_name: 'Гость',
  last_name: 'Тестовый',
  classification: :guest
)
puts "  ✓ Гость: #{guest.email}"

puts "\n📚 Создание категорий..."

courses_cat = Category.create!(
  name: 'Курсы',
  description: 'Обучающие курсы по методу Бронникова',
  position: 1
)
puts "  ✓ #{courses_cat.name}"

books_cat = Category.create!(
  name: 'Книги',
  description: 'Книги и методические материалы',
  position: 2
)
puts "  ✓ #{books_cat.name}"

videos_cat = Category.create!(
  name: 'Видеоматериалы',
  description: 'Видеозаписи семинаров и лекций',
  position: 3
)
puts "  ✓ #{videos_cat.name}"

services_cat = Category.create!(
  name: 'Услуги',
  description: 'Консультации и индивидуальные занятия',
  position: 4
)
puts "  ✓ #{services_cat.name}"

puts "\n🛍️  Создание продуктов..."

# Курсы
basic_course = Product.create!(
  name: 'Базовый курс',
  slug: 'bazovyi-kurs',
  category: courses_cat,
  description: 'Введение в метод Бронникова. Основы развития сверхспособностей.',
  price_kopecks: 1500000, # 15,000 руб
  product_type: :course,
  status: :published,
  featured: true,
  position: 1
)
puts "  ✓ #{basic_course.name} - #{basic_course.price.format}"

advanced_course = Product.create!(
  name: 'Продвинутый курс',
  slug: 'prodvinutyi-kurs',
  category: courses_cat,
  description: 'Углубленное изучение метода. Для тех, кто прошел базовый курс.',
  price_kopecks: 2500000, # 25,000 руб
  product_type: :course,
  status: :published,
  featured: true,
  position: 2
)
puts "  ✓ #{advanced_course.name} - #{advanced_course.price.format}"

# Книги
book1 = Product.create!(
  name: 'Метод Бронникова: Практическое руководство',
  slug: 'metod-bronnikova-praktika',
  category: books_cat,
  description: 'Практическое руководство по развитию сверхспособностей',
  price_kopecks: 50000, # 500 руб
  product_type: :book,
  status: :published,
  position: 1
)
puts "  ✓ #{book1.name} - #{book1.price.format}"

book2 = Product.create!(
  name: 'Информационное развитие человека',
  slug: 'informacionnoe-razvitie',
  category: books_cat,
  description: 'Теоретические основы метода Бронникова',
  price_kopecks: 40000, # 400 руб
  product_type: :book,
  status: :published,
  position: 2
)
puts "  ✓ #{book2.name} - #{book2.price.format}"

# Видео
video1 = Product.create!(
  name: 'Запись вебинара "Основы метода"',
  slug: 'webinar-osnovy',
  category: videos_cat,
  description: 'Видеозапись вводного вебинара',
  price_kopecks: 100000, # 1,000 руб
  product_type: :video,
  status: :published,
  featured: true,
  position: 1
)
puts "  ✓ #{video1.name} - #{video1.price.format}"

# Услуги
consultation = Product.create!(
  name: 'Индивидуальная консультация',
  slug: 'individualnaya-konsultaciya',
  category: services_cat,
  description: 'Персональная консультация со специалистом (1 час)',
  price_kopecks: 300000, # 3,000 руб
  product_type: :service,
  status: :published,
  position: 1
)
puts "  ✓ #{consultation.name} - #{consultation.price.format}"

# Черновик продукта (не опубликован)
draft_product = Product.create!(
  name: 'Мастер-класс (скоро)',
  slug: 'master-klass',
  category: courses_cat,
  description: 'Мастер-класс для продвинутых практиков',
  price_kopecks: 500000, # 5,000 руб
  product_type: :course,
  status: :draft,
  position: 10
)
puts "  ✓ #{draft_product.name} (черновик)"

puts "\n💳 Создание тестовых заказов..."

# Заказ клиента - оплачен из кошелька
order1 = client.orders.create!(
  total_kopecks: book1.price_kopecks + video1.price_kopecks,
  payment_method: 'wallet'
)
order1.order_items.create!(product: book1, price_kopecks: book1.price_kopecks, quantity: 1)
order1.order_items.create!(product: video1, price_kopecks: video1.price_kopecks, quantity: 1)
order1.pay! # автоматически создаст ProductAccess
puts "  ✓ Заказ ##{order1.order_number} (клиент, оплачен)"

# Заказ специалиста - оплачен
order2 = specialist.orders.create!(
  total_kopecks: advanced_course.price_kopecks,
  payment_method: 'wallet'
)
order2.order_items.create!(product: advanced_course, price_kopecks: advanced_course.price_kopecks, quantity: 1)
order2.pay!
order2.complete!
puts "  ✓ Заказ ##{order2.order_number} (специалист, завершен)"

# Заказ директора - в ожидании
order3 = director.orders.create!(
  total_kopecks: consultation.price_kopecks,
  payment_method: 'cloudpayments'
)
order3.order_items.create!(product: consultation, price_kopecks: consultation.price_kopecks, quantity: 1)
puts "  ✓ Заказ ##{order3.order_number} (директор, ожидание оплаты)"

puts "\n🗺️  Создание данных для карты развития..."

# Initiations
initiation1 = client.initiations.create!(
  initiation_type: 'Первая ступень',
  level: 1,
  conducted_by: specialist,
  conducted_at: 2.months.ago,
  status: :passed,
  notes: 'Успешно пройдена инициация первой ступени'
)
puts "  ✓ Инициация: #{initiation1.initiation_type} (клиент)"

initiation2 = specialist.initiations.create!(
  initiation_type: 'Третья ступень',
  level: 3,
  conducted_by: admin,
  conducted_at: 6.months.ago,
  status: :passed,
  notes: 'Инициация третьей ступени завершена успешно'
)
puts "  ✓ Инициация: #{initiation2.initiation_type} (специалист)"

# Diagnostics
diagnostic1 = client.diagnostics.create!(
  diagnostic_type: 'vision',
  conducted_by: specialist,
  conducted_at: 1.month.ago,
  status: :completed,
  score: 75,
  recommendations: 'Продолжайте развивать навыки визуализации'
)
puts "  ✓ Диагностика: Видение (клиент)"

diagnostic2 = specialist.diagnostics.create!(
  diagnostic_type: 'bioenergy',
  conducted_by: admin,
  conducted_at: 3.months.ago,
  status: :completed,
  score: 88,
  recommendations: 'Отличные результаты по биоэнергетике'
)
puts "  ✓ Диагностика: Биоэнергетика (специалист)"

puts "\n📅 Создание событий..."

event1 = Event.create!(
  title: 'Введение в метод Бронникова',
  description: 'Бесплатный вводный семинар для новичков. Узнайте основы метода и познакомьтесь с практиками.',
  starts_at: 2.weeks.from_now,
  ends_at: 2.weeks.from_now + 3.hours,
  is_online: true,
  price_kopecks: 0,
  status: :published,
  category: courses_cat,
  organizer: specialist
)
puts "  ✓ #{event1.title} (онлайн, бесплатно)"

event2 = Event.create!(
  title: 'Мастер-класс по развитию видения',
  description: 'Углубленная практика развития прямого видения с инструктором второй категории.',
  starts_at: 1.month.from_now,
  ends_at: 1.month.from_now + 4.hours,
  location: 'Москва, ул. Примерная, 15',
  is_online: false,
  max_participants: 20,
  price_kopecks: 350000, # 3,500 руб
  status: :published,
  category: courses_cat,
  organizer: admin
)
puts "  ✓ #{event2.title} (офлайн, платно)"

event3 = Event.create!(
  title: 'Диагностика уровня развития',
  description: 'Индивидуальная диагностика текущего уровня развития способностей.',
  starts_at: 3.days.from_now,
  ends_at: 3.days.from_now + 2.hours,
  is_online: true,
  max_participants: 10,
  price_kopecks: 200000, # 2,000 руб
  status: :published,
  category: services_cat,
  organizer: specialist
)
puts "  ✓ #{event3.title} (онлайн, платно)"

# Event registrations
reg1 = event1.event_registrations.create!(
  user: client,
  status: :confirmed
)
puts "  ✓ Регистрация клиента на бесплатное событие"

puts "\n📰 Создание статей и новостей..."

article1 = Article.create!(
  title: 'Открытие нового филиала в Санкт-Петербурге',
  excerpt: 'Рады сообщить об открытии нового центра развития в Санкт-Петербурге',
  content: 'Мы рады сообщить об открытии нового центра развития по методу Бронникова в Санкт-Петербурге. Приглашаем всех желающих на бесплатный день открытых дверей.',
  author: admin,
  article_type: :news,
  status: :published,
  featured: true,
  published_at: 1.week.ago
)
puts "  ✓ #{article1.title}"

article2 = Article.create!(
  title: 'Как начать практику развития видения',
  excerpt: 'Практические советы для новичков',
  content: 'В этой статье мы расскажем о первых шагах в практике развития прямого видения по методу Бронникова...',
  author: specialist,
  article_type: :useful_material,
  status: :published,
  featured: true,
  published_at: 3.days.ago
)
puts "  ✓ #{article2.title}"

article3 = Article.create!(
  title: 'Расписание семинаров на март 2026',
  excerpt: 'Обновленное расписание мероприятий',
  content: 'Публикуем расписание семинаров и мастер-классов на март 2026 года...',
  author: admin,
  article_type: :announcement,
  status: :published,
  published_at: 1.day.ago
)
puts "  ✓ #{article3.title}"

puts "\n📖 Создание Wiki страниц..."

wiki1 = WikiPage.create!(
  title: 'Основы метода Бронникова',
  content: 'Метод Бронникова - это комплексная система развития скрытых возможностей человека...',
  created_by: admin,
  updated_by: admin,
  status: :published,
  position: 1
)
puts "  ✓ #{wiki1.title}"

wiki2 = WikiPage.create!(
  title: 'Прямое видение',
  content: 'Прямое видение - способность воспринимать информацию без использования физических органов чувств...',
  parent: wiki1,
  created_by: specialist,
  updated_by: specialist,
  status: :published,
  position: 1
)
puts "  ✓ #{wiki2.title} (подраздел)"

wiki3 = WikiPage.create!(
  title: 'Биоэнергетика',
  content: 'Биоэнергетика изучает энергетические процессы в живых организмах...',
  parent: wiki1,
  created_by: specialist,
  updated_by: specialist,
  status: :published,
  position: 2
)
puts "  ✓ #{wiki3.title} (подраздел)"

puts "\n⭐ Создание избранного..."

Favorite.create!(user: client, favoritable: book1)
Favorite.create!(user: client, favoritable: article2)
Favorite.create!(user: client, favoritable: wiki1)
puts "  ✓ Клиент добавил 3 элемента в избранное"

puts "\n📊 Статистика:"
puts "  Пользователей: #{User.count}"
puts "  Категорий: #{Category.count}"
puts "  Продуктов: #{Product.count} (#{Product.published.count} опубликовано)"
puts "  Заказов: #{Order.count}"
puts "  Доступов к продуктам: #{ProductAccess.count}"
puts "  Инициаций: #{Initiation.count}"
puts "  Диагностик: #{Diagnostic.count}"
puts "  Событий: #{Event.count}"
puts "  Регистраций на события: #{EventRegistration.count}"
puts "  Статей: #{Article.count}"
puts "  Wiki страниц: #{WikiPage.count}"
puts "  Избранного: #{Favorite.count}"

puts "\n✅ Seed данные успешно загружены!"
puts "\n🔑 Тестовые учетные записи:"
puts "  Админ:       admin@bronnikov.com / password123"
puts "  Директор:    director@bronnikov.com / password123"
puts "  Специалист:  specialist@bronnikov.com / password123"
puts "  Клиент:      client@example.com / password123"
puts "  Гость:       guest@example.com / password123"

# Load integration settings and email templates
puts "\n📧 Загрузка настроек интеграций..."
load Rails.root.join('db/seeds/integrations.rb')

puts "\n📨 Загрузка email шаблонов..."
load Rails.root.join('db/seeds/email_templates.rb')
