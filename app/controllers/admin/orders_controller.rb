# frozen_string_literal: true

module Admin
  class OrdersController < BaseController
    before_action :set_order, only: [:show, :update]

    def index
      @orders = Order.includes(:user, :order_items).order(created_at: :desc)

      # Фильтр по статусу
      if params[:status].present?
        @orders = @orders.where(status: params[:status])
      end

      # Фильтр по дате
      if params[:date_from].present?
        @orders = @orders.where('created_at >= ?', params[:date_from])
      end

      if params[:date_to].present?
        @orders = @orders.where('created_at <= ?', params[:date_to].end_of_day)
      end

      # Поиск по номеру заказа или email пользователя
      if params[:search].present?
        @orders = @orders.left_joins(:user).where(
          'orders.order_number ILIKE ? OR users.email ILIKE ?',
          "%#{params[:search]}%",
          "%#{params[:search]}%"
        )
      end

      @orders = @orders.page(params[:page]).per(20)

      # Statistics
      @stats = calculate_stats
    end

    def show
      @items = @order.order_items.includes(:product)
    end

    def update
      action = params[:order_action]

      case action
      when 'refund'
        if @order.may_refund?
          @order.refund!
          redirect_to admin_order_path(@order), notice: 'Заказ возвращен'
        else
          redirect_to admin_order_path(@order), alert: 'Невозможно вернуть заказ в текущем статусе'
        end
      when 'complete'
        if @order.may_complete?
          @order.complete!
          redirect_to admin_order_path(@order), notice: 'Заказ завершен'
        else
          redirect_to admin_order_path(@order), alert: 'Невозможно завершить заказ в текущем статусе'
        end
      when 'cancel'
        if @order.may_cancel?
          @order.cancel!
          redirect_to admin_order_path(@order), notice: 'Заказ отменен'
        else
          redirect_to admin_order_path(@order), alert: 'Невозможно отменить заказ в текущем статусе'
        end
      else
        redirect_to admin_order_path(@order), alert: 'Неизвестное действие'
      end
    end

    private

    def set_order
      @order = Order.find(params[:id])
    end

    def calculate_stats
      {
        total_orders: Order.count,
        pending_orders: Order.where(status: :pending).count,
        paid_orders: Order.where(status: [:paid, :completed]).count,
        total_revenue: Order.where(status: [:paid, :completed]).sum(:total_kopecks),
        today_revenue: Order.where(status: [:paid, :completed])
                            .where('created_at >= ?', Time.current.beginning_of_day)
                            .sum(:total_kopecks),
        avg_order_value: Order.where(status: [:paid, :completed]).average(:total_kopecks) || 0
      }
    end
  end
end
