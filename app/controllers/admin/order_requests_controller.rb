# frozen_string_literal: true

module Admin
  class OrderRequestsController < ApplicationController
    before_action :authenticate_user!
    before_action :authorize_admin!
    before_action :set_order_request, only: [:show, :approve, :reject]

    def index
      @order_requests = OrderRequest.pending_approval
                                     .includes(:user, :product)
                                     .recent
                                     .page(params[:page])
                                     .per(20)
    end

    def show
      # @order_request set by before_action
    end

    def approve
      unless @order_request.status_pending?
        redirect_to admin_order_request_path(@order_request),
                    alert: 'Заявка уже обработана' and return
      end

      @order_request.update!(approved_by: current_user)
      @order_request.approve!

      if @order_request.status_paid?
        # Auto-payment succeeded after approval
        OrderRequestMailer.approved(@order_request).deliver_later
        redirect_to admin_order_request_path(@order_request),
                    notice: 'Заявка одобрена и автоматически оплачена!'
      elsif @order_request.status_approved?
        # Insufficient balance, waiting for user to top up
        OrderRequestMailer.insufficient_funds(@order_request).deliver_later
        redirect_to admin_order_request_path(@order_request),
                    notice: 'Заявка одобрена. Пользователю отправлено уведомление о пополнении кошелька.'
      else
        redirect_to admin_order_request_path(@order_request),
                    alert: 'Ошибка при одобрении заявки'
      end
    end

    def reject
      unless @order_request.status_pending?
        redirect_to admin_order_request_path(@order_request),
                    alert: 'Заявка уже обработана' and return
      end

      rejection_reason = params[:rejection_reason].to_s.strip

      if rejection_reason.blank?
        redirect_to admin_order_request_path(@order_request),
                    alert: 'Укажите причину отклонения' and return
      end

      @order_request.update!(rejection_reason: rejection_reason)
      @order_request.reject!

      OrderRequestMailer.rejected(@order_request).deliver_later

      redirect_to admin_order_requests_path,
                  notice: 'Заявка отклонена. Пользователю отправлено уведомление.'
    end

    private

    def set_order_request
      @order_request = OrderRequest.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to admin_order_requests_path, alert: 'Заявка не найдена'
    end

    def authorize_admin!
      unless current_user.can_approve_requests?
        redirect_to root_path, alert: 'Доступ запрещен' and return
      end
    end
  end
end
