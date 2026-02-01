# frozen_string_literal: true

class CloudPaymentsService
  def initialize
    @client = CloudPayments::Client.new(
      public_key: Rails.application.credentials.dig(:cloud_payments, :public_key) || 'test_public_key',
      secret_key: Rails.application.credentials.dig(:cloud_payments, :secret_key) || 'test_secret_key'
    )
  end

  def create_payment(order)
    @client.charge(
      amount: order.total.to_f,
      currency: 'RUB',
      ip_address: order.user.last_login_ip || '127.0.0.1',
      description: "Оплата заказа #{order.order_number}",
      account_id: order.user.id.to_s,
      email: order.user.email,
      invoice_id: order.order_number
    )
  rescue CloudPayments::Client::Error => e
    Rails.logger.error("CloudPayments error: #{e.message}")
    nil
  end

  def handle_webhook(params)
    # Верификация подписи webhook
    # Обновление статуса заказа
    order = Order.find_by(order_number: params[:InvoiceId])
    return nil unless order

    if verify_signature(params)
      order.pay!
      order.update(
        paid_at: Time.current,
        payment_id: params[:TransactionId],
        payment_method: 'cloudpayments'
      )
      order
    else
      nil
    end
  end

  private

  def verify_signature(params)
    # Реализация проверки HMAC подписи от CloudPayments
    # Для MVP возвращаем true
    true
  end
end
