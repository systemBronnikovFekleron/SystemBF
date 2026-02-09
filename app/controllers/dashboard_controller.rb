# frozen_string_literal: true

class DashboardController < ApplicationController
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
    @notifications = current_user.notifications.recent.page(params[:page]).per(20)
    @unread_count = current_user.notifications.unread.count
  end

  def mark_notification_read
    notification = current_user.notifications.find(params[:id])
    notification.mark_as_read!
    head :ok
  end

  def settings
    # @user уже установлен в before_action
  end

  def orders
    @orders = @user.orders.order(created_at: :desc)
  end

  # Development Map
  def development_map
    @initiations = @user.initiations.includes(:conducted_by).ordered
    @diagnostics = @user.diagnostics.includes(:conducted_by).ordered
    @product_accesses = @user.product_accesses.includes(:product)
    @timeline_events = build_development_timeline
  end

  # Content pages
  def favorites
    @favorites = @user.favorites.includes(:favoritable).ordered
  end

  def news
    @news = Article.published.accessible_by(current_user).article_type_news.ordered.page(params[:page]).per(10)
  end

  def materials
    @materials = Article.published.accessible_by(current_user).article_type_useful_material.ordered.page(params[:page]).per(10)
  end

  def wiki
    @root_pages = WikiPage.published.accessible_by(current_user).root_pages.ordered
  end

  def wiki_show
    @page = WikiPage.friendly.find(params[:slug])
    unless @page.accessible_by?(current_user)
      redirect_to dashboard_wiki_path, alert: 'У вас нет доступа к этой странице'
      return
    end
    @children = @page.children.published.accessible_by(current_user).ordered
  end

  def recommendations
    @recommended_products = recommend_products_for(@user)
    @recommended_articles = recommend_articles_for(@user)
  end

  # Events
  def events
    @upcoming = @user.event_registrations
                     .joins(:event)
                     .where('events.starts_at > ?', Time.current)
                     .includes(:event)
                     .order('events.starts_at ASC')

    @past = @user.event_registrations
                 .joins(:event)
                 .where('events.starts_at <= ?', Time.current)
                 .includes(:event)
                 .order('events.starts_at DESC')
  end

  # Export user calendar as ICS
  def calendar_ics
    ics_content = IcsGeneratorService.generate_user_calendar(@user)

    send_data ics_content,
              type: 'text/calendar; charset=utf-8',
              disposition: 'attachment',
              filename: 'my-calendar.ics'
  end

  def update_profile
    ActiveRecord::Base.transaction do
      if @user.update(user_params) && @user.profile.update(profile_params)
        redirect_to dashboard_profile_path, notice: 'Профиль успешно обновлен'
      else
        render :profile, status: :unprocessable_entity
      end
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

  def user_params
    params.permit(:first_name, :last_name)
  end

  def profile_params
    params.require(:profile).permit(:phone, :city, :country, :birth_date, :bio)
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

  def build_development_timeline
    events = []

    # Add initiations
    @initiations.each do |init|
      events << {
        type: 'initiation',
        date: init.conducted_at || init.created_at,
        title: "Инициация: #{init.initiation_type}",
        data: init
      }
    end

    # Add diagnostics
    @diagnostics.each do |diag|
      events << {
        type: 'diagnostic',
        date: diag.conducted_at || diag.created_at,
        title: diag.display_name,
        data: diag
      }
    end

    # Add product accesses
    @product_accesses.each do |access|
      events << {
        type: 'product_access',
        date: access.created_at,
        title: "Получен доступ: #{access.product.name}",
        data: access
      }
    end

    events.sort_by { |e| e[:date] }.reverse
  end

  def recommend_products_for(user)
    # Simple algorithm: products from same categories user purchased
    categories = user.product_accesses.joins(:product).pluck('products.category_id').uniq
    Product.published
           .where(category_id: categories)
           .where.not(id: user.product_accesses.pluck(:product_id))
           .limit(6)
  end

  def recommend_articles_for(user)
    Article.published.featured.limit(3)
  end
end
