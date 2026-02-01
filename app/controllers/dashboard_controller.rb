# frozen_string_literal: true

class DashboardController < ApplicationController
  layout 'dashboard'
  skip_before_action :verify_authenticity_token

  def index
    # TODO: Получить текущего пользователя из сессии
    @user = User.first || create_demo_user
    @recent_orders = @user.orders.order(created_at: :desc).limit(5)
    @product_accesses = @user.product_accesses.includes(:product).limit(6)
    @stats = calculate_stats(@user)
  end

  def profile
    @user = User.first || create_demo_user
  end

  def wallet
    @user = User.first || create_demo_user
    @transactions = [] # TODO: Implement transactions
  end

  def rating
    @user = User.first || create_demo_user
  end

  def orders
    @user = User.first || create_demo_user
    @orders = @user.orders.order(created_at: :desc)
  end

  private

  def create_demo_user
    User.create!(
      email: 'demo@example.com',
      password: 'password123',
      password_confirmation: 'password123',
      first_name: 'Демо',
      last_name: 'Пользователь',
      classification: :client
    )
  end

  def calculate_stats(user)
    {
      total_spent: user.orders.where(status: [:paid, :completed]).sum(:total_kopecks),
      total_orders: user.orders.count,
      completed_courses: user.product_accesses.joins(:product).where(products: { product_type: 'course' }).count,
      active_days: (Date.today - user.created_at.to_date).to_i
    }
  end

  def current_user
    @user
  end
  helper_method :current_user
end
