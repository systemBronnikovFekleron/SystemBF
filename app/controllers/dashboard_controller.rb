# frozen_string_literal: true

class DashboardController < ApplicationController
  layout 'dashboard'
  skip_before_action :verify_authenticity_token
  before_action :authenticate_user!
  before_action :set_user

  def index
    @recent_orders = @user.orders.includes(:order_items).order(created_at: :desc).limit(5)
    @product_accesses = @user.product_accesses.includes(:product).limit(6)
    @stats = calculate_stats(@user)
  end

  def profile
    # @user уже установлен в before_action
  end

  def wallet
    @transactions = [] # TODO: Implement transactions
  end

  def rating
    @leaderboard = User.joins(:rating).order('ratings.points DESC').limit(10)
  end

  def my_courses
    @product_accesses = @user.product_accesses.includes(:product)
  end

  def achievements
    # Mock achievements data (будет заменено на реальную модель Achievement)
    @achievements = generate_mock_achievements
  end

  def notifications
    # Mock notifications data (будет заменено на реальную модель Notification)
    @notifications = generate_mock_notifications
  end

  def settings
    # @user уже установлен в before_action
  end

  def orders
    @orders = @user.orders.order(created_at: :desc)
  end

  def update_profile
    if @user.profile.update(profile_params)
      redirect_to dashboard_profile_path, notice: 'Профиль успешно обновлен'
    else
      render :profile, status: :unprocessable_entity
    end
  end

  def deposit_wallet
    amount_rubles = params[:amount].to_i
    if amount_rubles < 100
      redirect_to dashboard_wallet_path, alert: 'Минимальная сумма пополнения: 100 ₽'
      return
    end

    amount_kopecks = amount_rubles * 100

    # Создаем специальный заказ для пополнения кошелька
    order = Order.create!(
      user: @user,
      total_kopecks: amount_kopecks,
      status: :pending,
      order_number: generate_order_number
    )

    # Перенаправляем на страницу оплаты
    redirect_to new_order_payment_path(order)
  end

  private

  def set_user
    @user = current_user
  end

  def calculate_stats(user)
    {
      total_spent: user.orders.where(status: [:paid, :completed]).sum(:total_kopecks),
      total_orders: user.orders.count,
      completed_courses: user.product_accesses.joins(:product).where(products: { product_type: 'course' }).count,
      active_days: (Date.today - user.created_at.to_date).to_i
    }
  end

  def profile_params
    params.require(:profile).permit(:first_name, :last_name, :phone, :city, :country, :birth_date, :bio)
  end

  def generate_order_number
    # Формат: BR-YYYY-NNNN (BR = Bronnikov, YYYY = год, NNNN = последовательный номер)
    year = Date.today.year
    last_order = Order.where("order_number LIKE ?", "BR-#{year}-%").order(:created_at).last
    sequence = last_order ? last_order.order_number.split('-').last.to_i + 1 : 1
    "BR-#{year}-#{sequence.to_s.rjust(4, '0')}"
  end

  def generate_mock_achievements
    [
      # Learning achievements
      { id: 1, name: 'Первый шаг', description: 'Завершите ваш первый курс', icon: '🎓', category: 'learning', points: 50, unlocked: true, unlocked_at: 10.days.ago },
      { id: 2, name: 'Книжный червь', description: 'Прочитайте 5 книг', icon: '📚', category: 'learning', points: 100, unlocked: false, unlocked_at: nil },
      { id: 3, name: 'Мастер обучения', description: 'Завершите 10 курсов', icon: '🎯', category: 'learning', points: 200, unlocked: false, unlocked_at: nil },
      { id: 4, name: 'Видеоман', description: 'Просмотрите 20 видеоуроков', icon: '🎬', category: 'learning', points: 75, unlocked: true, unlocked_at: 5.days.ago },

      # Purchase achievements
      { id: 5, name: 'Первая покупка', description: 'Совершите первую покупку', icon: '💰', category: 'purchases', points: 25, unlocked: true, unlocked_at: 15.days.ago },
      { id: 6, name: 'Щедрый покупатель', description: 'Потратьте более 10000 ₽', icon: '💎', category: 'purchases', points: 150, unlocked: false, unlocked_at: nil },
      { id: 7, name: 'VIP клиент', description: 'Потратьте более 50000 ₽', icon: '👑', category: 'purchases', points: 500, unlocked: false, unlocked_at: nil },

      # Social achievements
      { id: 8, name: 'Новичок', description: 'Зарегистрируйтесь на платформе', icon: '👋', category: 'social', points: 10, unlocked: true, unlocked_at: 30.days.ago },
      { id: 9, name: 'Делимся знаниями', description: 'Пригласите 3 друзей', icon: '🤝', category: 'social', points: 100, unlocked: false, unlocked_at: nil },
      { id: 10, name: 'Постоянный ученик', description: 'Войдите 30 дней подряд', icon: '🔥', category: 'social', points: 200, unlocked: false, unlocked_at: nil },
      { id: 11, name: 'Комментатор', description: 'Оставьте 10 комментариев', icon: '💬', category: 'social', points: 50, unlocked: false, unlocked_at: nil },
      { id: 12, name: 'Эксперт', description: 'Получите 100 лайков на комментариях', icon: '⭐', category: 'social', points: 150, unlocked: false, unlocked_at: nil }
    ]
  end

  def generate_mock_notifications
    [
      # Today
      { id: 1, type: 'order_paid', title: 'Заказ оплачен', message: 'Ваш заказ #BR-2026-0001 успешно оплачен. Доступ к материалам открыт.', created_at: 2.hours.ago, read: false, action_url: '/dashboard/orders', action_text: 'Смотреть заказ' },
      { id: 2, type: 'product_access_granted', title: 'Доступ открыт', message: 'Вам открыт доступ к курсу "Основы видения". Начните обучение прямо сейчас!', created_at: 3.hours.ago, read: false, action_url: '/dashboard/my-courses', action_text: 'Начать обучение' },

      # Yesterday
      { id: 3, type: 'achievement_unlocked', title: 'Новое достижение!', message: 'Поздравляем! Вы получили достижение "Первая покупка" (+25 очков рейтинга)', created_at: 1.day.ago, read: true, action_url: '/dashboard/achievements', action_text: 'Смотреть достижения' },
      { id: 4, type: 'wallet_deposit', title: 'Кошелек пополнен', message: 'Ваш кошелек пополнен на 1000 ₽', created_at: 1.day.ago, read: true, action_url: '/dashboard/wallet' },

      # 2 days ago
      { id: 5, type: 'system', title: 'Обновление платформы', message: 'Мы добавили новые функции в личный кабинет. Ознакомьтесь с изменениями.', created_at: 2.days.ago, read: true, action_url: '#' },

      # 5 days ago
      { id: 6, type: 'profile_updated', title: 'Профиль обновлен', message: 'Данные вашего профиля успешно сохранены', created_at: 5.days.ago, read: true, action_url: '/dashboard/profile' }
    ]
  end
end
