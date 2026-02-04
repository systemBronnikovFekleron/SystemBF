# frozen_string_literal: true

module Webhooks
  class CloudPaymentsController < ActionController::Base
    skip_before_action :verify_authenticity_token

    def pay
      # New architecture: CloudPayments deposits to wallet, then auto-purchases approved requests
      # InvoiceId format: "WALLET-{user_id}-{timestamp}" for wallet deposits
      # or "ORDER-{order_number}" for legacy order payments

      if params[:InvoiceId]&.start_with?('WALLET-')
        handle_wallet_deposit
      else
        handle_legacy_order_payment
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

    def verify_signature(webhook_params)
      # CloudPayments HMAC-SHA256 verification
      # https://developers.cloudpayments.ru/#podpis-uvedomleniy

      return false unless webhook_params[:Signature].present?

      api_secret = Rails.application.credentials.dig(:cloudpayments, :api_secret)
      return false unless api_secret

      # Строка для подписи состоит из конкатенации параметров в определенном порядке
      # Для разных типов уведомлений разные параметры
      signature_string = case action_name
                         when 'pay'
                           # Успешный платеж: InvoiceId|Amount|Currency|DateTime|IpAddress|...
                           build_pay_signature_string(webhook_params)
                         when 'refund'
                           # Возврат: InvoiceId|Amount|DateTime
                           build_refund_signature_string(webhook_params)
                         else
                           return false
                         end

      expected_signature = OpenSSL::HMAC.hexdigest('SHA256', api_secret, signature_string)
      actual_signature = webhook_params[:Signature]

      # Используем secure_compare для защиты от timing attacks
      ActiveSupport::SecurityUtils.secure_compare(expected_signature, actual_signature)
    rescue StandardError => e
      Rails.logger.error "CloudPayments signature verification failed: #{e.message}"
      false
    end

    def build_pay_signature_string(params)
      # Для pay webhook CloudPayments формирует строку из следующих полей:
      # InvoiceId|Amount|Currency|DateTime|IpAddress|IpCountry|IpCity|IpRegion|IpDistrict|IpLatitude|IpLongitude|...
      # Полный список: https://developers.cloudpayments.ru/#uvedomlenie-o-uspeshnom-platezhe

      [
        params[:InvoiceId],
        params[:Amount],
        params[:Currency],
        params[:DateTime],
        params[:IpAddress],
        params[:IpCountry],
        params[:IpCity],
        params[:IpRegion],
        params[:IpDistrict],
        params[:IpLatitude],
        params[:IpLongitude],
        params[:AccountId],
        params[:Email],
        params[:CardFirstSix],
        params[:CardLastFour],
        params[:CardExpDate],
        params[:IssuerBankCountry],
        params[:Description],
        params[:Data]
      ].compact.join('|')
    end

    def build_refund_signature_string(params)
      # Для refund webhook CloudPayments использует упрощенную строку
      [
        params[:InvoiceId],
        params[:Amount],
        params[:DateTime]
      ].compact.join('|')
    end

    def handle_wallet_deposit
      # Parse user_id from InvoiceId: "WALLET-{user_id}-{timestamp}"
      match = params[:InvoiceId].match(/^WALLET-(\d+)-\d+$/)
      unless match
        render json: { code: 1, error: 'Invalid InvoiceId format' } and return
      end

      user_id = match[1].to_i
      user = User.find_by(id: user_id)

      unless user
        render json: { code: 1, error: 'User not found' } and return
      end

      unless verify_signature(params)
        render json: { code: 1, error: 'Invalid signature' } and return
      end

      # Amount is in rubles, convert to kopecks
      amount_rubles = params[:Amount].to_f
      amount_kopecks = (amount_rubles * 100).to_i

      begin
        # Deposit to wallet with transaction record
        user.wallet.deposit_with_transaction(
          amount_kopecks,
          params[:TransactionId],
          "Пополнение через CloudPayments: #{amount_rubles} ₽"
        )

        # Auto-purchase approved order requests
        process_auto_purchases(user)

        render json: { code: 0 }
      rescue StandardError => e
        Rails.logger.error "Wallet deposit failed: #{e.message}"
        render json: { code: 1, error: 'Deposit failed' }
      end
    end

    def handle_legacy_order_payment
      # Legacy flow: direct order payment (keep for backwards compatibility)
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

    def process_auto_purchases(user)
      # Find all approved order requests waiting for payment
      pending_requests = user.order_requests
                             .where(status: 'approved')
                             .order(created_at: :asc)

      pending_requests.each do |request|
        break unless user.wallet.sufficient_balance?(request.total_kopecks)

        begin
          user.wallet.withdraw_with_transaction(request.total_kopecks, request)
          request.pay!

          # Send notification about auto-purchase
          OrderRequestMailer.auto_paid(request).deliver_later
        rescue StandardError => e
          Rails.logger.error "Auto-purchase failed for OrderRequest #{request.id}: #{e.message}"
          break
        end
      end
    end
  end
end
