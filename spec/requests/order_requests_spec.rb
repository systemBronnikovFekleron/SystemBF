# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'OrderRequests', type: :request do
  let(:user) { create(:user) }
  let(:product) { create(:product, price_kopecks: 100_000, status: 'published') }

  before do
    sign_in user
  end

  describe 'GET /order_requests' do
    it 'returns success' do
      get order_requests_path
      expect(response).to have_http_status(:success)
    end

    it 'displays user order requests' do
      request1 = create(:order_request, user: user)
      request2 = create(:order_request, user: user)
      other_request = create(:order_request)

      get order_requests_path

      expect(response.body).to include(request1.request_number)
      expect(response.body).to include(request2.request_number)
      expect(response.body).not_to include(other_request.request_number)
    end
  end

  describe 'GET /order_requests/:id' do
    let(:order_request) { create(:order_request, user: user) }

    it 'returns success' do
      get order_request_path(order_request)
      expect(response).to have_http_status(:success)
    end

    it 'displays request details' do
      get order_request_path(order_request)
      expect(response.body).to include(order_request.request_number)
      expect(response.body).to include(order_request.product.name)
    end

    context 'when trying to access another user request' do
      let(:other_request) { create(:order_request) }

      it 'redirects to index' do
        get order_request_path(other_request)
        expect(response).to redirect_to(order_requests_path)
      end
    end
  end

  describe 'POST /order_requests' do
    context 'with valid product' do
      it 'creates new order request' do
        expect {
          post order_requests_path, params: { product_id: product.id }
        }.to change { OrderRequest.count }.by(1)
      end

      it 'sets correct attributes' do
        post order_requests_path, params: { product_id: product.id }

        request = OrderRequest.last
        expect(request.user).to eq(user)
        expect(request.product).to eq(product)
        expect(request.total_kopecks).to eq(product.price_kopecks)
        expect(request.status).to eq('pending')
      end

      context 'with auto_approve enabled and sufficient balance' do
        before do
          product.update(auto_approve: true)
          user.wallet.update(balance_kopecks: 150_000)
        end

        it 'auto-approves and pays the request' do
          post order_requests_path, params: { product_id: product.id }

          request = OrderRequest.last
          expect(request.status).to eq('completed')
          expect(request.order).to be_present
        end

        it 'creates wallet transaction' do
          expect {
            post order_requests_path, params: { product_id: product.id }
          }.to change { user.wallet.wallet_transactions.count }.by(1)
        end

        it 'reduces wallet balance' do
          expect {
            post order_requests_path, params: { product_id: product.id }
          }.to change { user.wallet.reload.balance_kopecks }.by(-product.price_kopecks)
        end

        it 'redirects to order' do
          post order_requests_path, params: { product_id: product.id }
          request = OrderRequest.last
          expect(response).to redirect_to(order_path(request.order))
        end
      end

      context 'with auto_approve but insufficient balance' do
        before do
          product.update(auto_approve: true)
          user.wallet.update(balance_kopecks: 50_000)
        end

        it 'approves but does not pay' do
          post order_requests_path, params: { product_id: product.id }

          request = OrderRequest.last
          expect(request.status).to eq('approved')
          expect(request.order).to be_nil
        end

        it 'redirects to payment options' do
          post order_requests_path, params: { product_id: product.id }
          request = OrderRequest.last
          expect(response).to redirect_to(payment_options_order_request_path(request))
        end
      end

      context 'without auto_approve' do
        it 'creates pending request' do
          post order_requests_path, params: { product_id: product.id }

          request = OrderRequest.last
          expect(request.status).to eq('pending')
        end

        it 'redirects to request show page' do
          post order_requests_path, params: { product_id: product.id }
          request = OrderRequest.last
          expect(response).to redirect_to(order_request_path(request))
        end
      end
    end

    context 'with unpublished product' do
      let(:draft_product) { create(:product, status: 'draft') }

      it 'does not create request' do
        expect {
          post order_requests_path, params: { product_id: draft_product.id }
        }.not_to change { OrderRequest.count }
      end

      it 'redirects to products index' do
        post order_requests_path, params: { product_id: draft_product.id }
        expect(response).to redirect_to(products_path)
      end
    end
  end

  describe 'GET /order_requests/:id/payment_options' do
    let(:approved_request) { create(:order_request, :approved, user: user, product: product) }

    it 'returns success' do
      get payment_options_order_request_path(approved_request)
      expect(response).to have_http_status(:success)
    end

    context 'with pending request' do
      let(:pending_request) { create(:order_request, user: user, product: product) }

      it 'redirects back' do
        get payment_options_order_request_path(pending_request)
        expect(response).to redirect_to(order_request_path(pending_request))
      end
    end
  end

  describe 'POST /order_requests/:id/pay' do
    let(:approved_request) { create(:order_request, :approved, user: user, product: product) }

    context 'with sufficient balance' do
      before do
        user.wallet.update(balance_kopecks: 150_000)
      end

      it 'pays the request' do
        expect {
          post pay_order_request_path(approved_request)
        }.to change { approved_request.reload.status }.from('approved').to('paid')
      end

      it 'creates order' do
        expect {
          post pay_order_request_path(approved_request)
        }.to change { Order.count }.by(1)
      end

      it 'creates wallet transaction' do
        expect {
          post pay_order_request_path(approved_request)
        }.to change { user.wallet.wallet_transactions.count }.by(1)
      end

      it 'reduces balance' do
        expect {
          post pay_order_request_path(approved_request)
        }.to change { user.wallet.reload.balance_kopecks }.by(-product.price_kopecks)
      end

      it 'redirects to order' do
        post pay_order_request_path(approved_request)
        expect(response).to redirect_to(order_path(approved_request.reload.order))
      end
    end

    context 'with insufficient balance' do
      before do
        user.wallet.update(balance_kopecks: 50_000)
      end

      it 'does not pay the request' do
        expect {
          post pay_order_request_path(approved_request)
        }.not_to change { approved_request.reload.status }
      end

      it 'redirects to payment options' do
        post pay_order_request_path(approved_request)
        expect(response).to redirect_to(payment_options_order_request_path(approved_request))
      end
    end

    context 'with pending request' do
      let(:pending_request) { create(:order_request, user: user, product: product) }

      it 'does not pay' do
        expect {
          post pay_order_request_path(pending_request)
        }.not_to change { pending_request.reload.status }
      end

      it 'redirects back' do
        post pay_order_request_path(pending_request)
        expect(response).to redirect_to(order_request_path(pending_request))
      end
    end
  end
end
