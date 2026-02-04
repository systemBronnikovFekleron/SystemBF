# frozen_string_literal: true

module Admin
  class DashboardController < BaseController
    def index
      @stats = {
        total_products: Product.count,
        published_products: Product.published.count,
        draft_products: Product.draft.count,
        total_users: User.count,
        new_users_this_month: User.where('created_at >= ?', 1.month.ago).count,
        total_orders: Order.count,
        paid_orders: Order.where(status: [:paid, :completed]).count,
        revenue_this_month: Order.where(status: [:paid, :completed])
                                 .where('created_at >= ?', 1.month.ago)
                                 .sum(:total_kopecks)
      }

      @recent_orders = Order.includes(:user).order(created_at: :desc).limit(5)
      @recent_users = User.order(created_at: :desc).limit(5)

      # Chart data
      @revenue_by_day = calculate_revenue_by_day
      @users_by_classification = User.group(:classification).count
      @top_products = calculate_top_products
    end

    private

    def calculate_revenue_by_day
      # Last 30 days revenue
      30.days.ago.to_date.upto(Date.today).map do |date|
        revenue = Order.where(status: [:paid, :completed])
                       .where('DATE(created_at) = ?', date)
                       .sum(:total_kopecks)
        {
          date: date.strftime('%d.%m'),
          revenue: revenue / 100.0 # Convert to rubles
        }
      end
    end

    def calculate_top_products
      # Top 10 products by revenue
      OrderItem.joins(:order, :product)
               .where(orders: { status: [:paid, :completed] })
               .group('products.id', 'products.name')
               .select('products.name, SUM(order_items.price_kopecks * order_items.quantity) as total_revenue')
               .order('total_revenue DESC')
               .limit(10)
               .map do |item|
        {
          name: item.name,
          revenue: item.total_revenue / 100.0 # Convert to rubles
        }
      end
    end
  end
end
