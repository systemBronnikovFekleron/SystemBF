# frozen_string_literal: true

class OrderRequestsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_order_request, only: [:show, :payment_options, :pay]

  def index
    @order_requests = current_user.order_requests.recent.page(params[:page]).per(10)
  end

  def show
    # @order_request set by before_action
  end

  def create
    @product = Product.friendly.find(params[:product_id])

    unless @product.status == 'published'
      redirect_to products_path, alert: 'Продукт недоступен для покупки' and return
    end

    @order_request = current_user.order_requests.build(
      product: @product,
      form_data: filtered_form_data
    )

    if @order_request.save
      handle_after_creation
    else
      redirect_to product_path(@product), alert: @order_request.errors.full_messages.join(', ')
    end
  end

  def payment_options
    # @order_request set by before_action
    unless @order_request.status_approved?
      redirect_to order_request_path(@order_request), alert: 'Заявка еще не одобрена' and return
    end

    @wallet = current_user.wallet
    @shortfall = @order_request.total_kopecks - @wallet.balance_kopecks
  end

  def pay
    unless @order_request.status_approved?
      redirect_to order_request_path(@order_request), alert: 'Заявка еще не одобрена' and return
    end

    unless current_user.wallet.sufficient_balance?(@order_request.total_kopecks)
      redirect_to payment_options_order_request_path(@order_request),
                  alert: 'Недостаточно средств на кошельке' and return
    end

    begin
      current_user.wallet.withdraw_with_transaction(@order_request.total_kopecks, @order_request)
      @order_request.pay!

      redirect_to order_path(@order_request.order), notice: 'Заказ успешно оплачен!'
    rescue StandardError => e
      Rails.logger.error "Payment failed for OrderRequest #{@order_request.id}: #{e.message}"
      redirect_to payment_options_order_request_path(@order_request),
                  alert: 'Ошибка при оплате. Попробуйте позже.'
    end
  end

  private

  def set_order_request
    @order_request = current_user.order_requests.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to order_requests_path, alert: 'Заявка не найдена'
  end

  def filtered_form_data
    return {} unless params[:form_data].present?

    params.require(:form_data).permit!.to_h
  end

  def handle_after_creation
    if @product.auto_approve
      @order_request.approve!
      @order_request.update!(approved_by: nil) # Auto-approve has no approver

      if @order_request.status_paid?
        # Auto-payment succeeded
        redirect_to order_path(@order_request.order),
                    notice: 'Продукт успешно куплен и доступен в личном кабинете!'
      else
        # Insufficient balance
        redirect_to payment_options_order_request_path(@order_request),
                    alert: 'Недостаточно средств. Пополните кошелек для завершения покупки.'
      end
    else
      # Manual approval required
      redirect_to order_request_path(@order_request),
                  notice: 'Заявка создана. Ожидайте одобрения администратора.'
    end
  end
end
