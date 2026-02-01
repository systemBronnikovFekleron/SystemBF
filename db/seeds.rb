# frozen_string_literal: true

# Очистка базы данных (только для development)
if Rails.env.development?
  puts "🗑️  Очистка базы данных..."
  ProductAccess.destroy_all
  OrderItem.destroy_all
  Order.destroy_all
  Product.destroy_all
  Category.destroy_all
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

puts "\n📊 Статистика:"
puts "  Пользователей: #{User.count}"
puts "  Категорий: #{Category.count}"
puts "  Продуктов: #{Product.count} (#{Product.published.count} опубликовано)"
puts "  Заказов: #{Order.count}"
puts "  Доступов к продуктам: #{ProductAccess.count}"

puts "\n✅ Seed данные успешно загружены!"
puts "\n🔑 Тестовые учетные записи:"
puts "  Админ:       admin@bronnikov.com / password123"
puts "  Директор:    director@bronnikov.com / password123"
puts "  Специалист:  specialist@bronnikov.com / password123"
puts "  Клиент:      client@example.com / password123"
puts "  Гость:       guest@example.com / password123"
