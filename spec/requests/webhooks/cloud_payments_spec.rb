# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'CloudPayments Webhooks', type: :request do
  let(:user) { create(:user) }
  let(:product) { create(:product, :published) }
  let(:order) { create(:order, user: user, status: :pending) }
  let!(:order_item) { create(:order_item, order: order, product: product) }

  describe 'POST /webhooks/cloudpayments/pay' do
    let(:webhook_params) { cloudpayments_pay_params(order) }

    context 'with valid signature' do
      before do
        webhook_params[:Signature] = generate_cloudpayments_signature(order, webhook_params[:Amount])
      end

      it 'marks order as paid' do
        post webhooks_cloudpayments_pay_path, params: webhook_params

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['code']).to eq(0)
        expect(order.reload.status).to eq('paid')
      end

      it 'updates order payment details' do
        post webhooks_cloudpayments_pay_path, params: webhook_params

        order.reload
        expect(order.payment_id).to eq(webhook_params[:TransactionId])
        expect(order.payment_method).to eq('cloudpayments')
        expect(order.paid_at).to be_present
      end

      it 'grants product access for digital products' do
        expect {
          post webhooks_cloudpayments_pay_path, params: webhook_params
        }.to change { ProductAccess.count }.by(1)

        product_access = ProductAccess.last
        expect(product_access.user).to eq(user)
        expect(product_access.product).to eq(product)
      end

      it 'sends payment received email' do
        expect {
          post webhooks_cloudpayments_pay_path, params: webhook_params
        }.to have_enqueued_job.on_queue('default')
      end
    end

    context 'with invalid signature' do
      before do
        webhook_params[:Signature] = 'invalid_signature_123'
      end

      it 'rejects the webhook' do
        post webhooks_cloudpayments_pay_path, params: webhook_params

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['code']).to eq(1)
        expect(order.reload.status).to eq('pending')
      end

      it 'does not update order' do
        expect {
          post webhooks_cloudpayments_pay_path, params: webhook_params
          order.reload
        }.not_to change(order, :status)
      end

      it 'does not grant product access' do
        expect {
          post webhooks_cloudpayments_pay_path, params: webhook_params
        }.not_to change { ProductAccess.count }
      end
    end

    context 'with missing signature' do
      before do
        webhook_params.delete(:Signature)
      end

      it 'rejects the webhook' do
        post webhooks_cloudpayments_pay_path, params: webhook_params

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['code']).to eq(1)
      end
    end

    context 'with non-existent order' do
      before do
        webhook_params[:InvoiceId] = 'BR-2099-9999'
        webhook_params[:Signature] = generate_cloudpayments_signature(order, webhook_params[:Amount])
      end

      it 'returns error' do
        post webhooks_cloudpayments_pay_path, params: webhook_params

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['code']).to eq(1)
      end
    end
  end

  describe 'POST /webhooks/cloudpayments/fail' do
    it 'marks order as failed' do
      post webhooks_cloudpayments_fail_path, params: {
        InvoiceId: order.order_number,
        Amount: order.total_kopecks / 100.0
      }

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['code']).to eq(0)
      expect(order.reload.status).to eq('failed')
    end

    context 'with non-existent order' do
      it 'returns error' do
        post webhooks_cloudpayments_fail_path, params: {
          InvoiceId: 'BR-2099-9999'
        }

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['code']).to eq(1)
      end
    end
  end

  describe 'POST /webhooks/cloudpayments/refund' do
    let(:paid_order) { create(:order, user: user, status: :paid) }
    let(:webhook_params) do
      {
        InvoiceId: paid_order.order_number,
        Amount: paid_order.total_kopecks / 100.0,
        DateTime: Time.current.utc.iso8601
      }
    end

    context 'with valid signature' do
      before do
        data = [
          webhook_params[:InvoiceId],
          webhook_params[:Amount],
          webhook_params[:DateTime]
        ].join('|')

        api_secret = Rails.application.credentials.dig(:cloudpayments, :api_secret) || 'test_secret'
        webhook_params[:Signature] = OpenSSL::HMAC.hexdigest('SHA256', api_secret, data)
      end

      it 'marks order as refunded' do
        post webhooks_cloudpayments_refund_path, params: webhook_params

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['code']).to eq(0)
        expect(paid_order.reload.status).to eq('refunded')
      end
    end

    context 'with invalid signature' do
      before do
        webhook_params[:Signature] = 'invalid_signature'
      end

      it 'rejects the webhook' do
        post webhooks_cloudpayments_refund_path, params: webhook_params

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['code']).to eq(1)
        expect(paid_order.reload.status).to eq('paid')
      end
    end
  end
end
