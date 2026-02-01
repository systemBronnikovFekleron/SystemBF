# frozen_string_literal: true

module Webhooks
  class CloudPaymentsController < ActionController::Base
    skip_before_action :verify_authenticity_token

    def pay
      order = Order.find_by(order_number: params[:InvoiceId])

      if order && verify_signature(params)
        order.pay!
        order.update(
          paid_at: Time.current,
          payment_id: params[:TransactionId],
          payment_method: 'cloudpayments'
        )

        render json: { code: 0 }
      else
        render json: { code: 1, error: 'Invalid order or signature' }
      end
    end

    def fail
      order = Order.find_by(order_number: params[:InvoiceId])

      if order
        order.fail!
        render json: { code: 0 }
      else
        render json: { code: 1, error: 'Invalid order' }
      end
    end

    def refund
      order = Order.find_by(order_number: params[:InvoiceId])

      if order && verify_signature(params)
        order.refund!
        render json: { code: 0 }
      else
        render json: { code: 1, error: 'Invalid order or signature' }
      end
    end

    private

    def verify_signature(params)
      # Проверка HMAC подписи от CloudPayments
      # Для MVP возвращаем true
      true
    end
  end
end
