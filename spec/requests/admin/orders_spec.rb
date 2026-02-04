# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin::Orders', type: :request do
  let(:admin) { create(:user, :admin) }
  let(:user) { create(:user, :client) }

  before { sign_in(admin) }

  describe 'GET /admin/orders' do
    let!(:orders) { create_list(:order, 3, user: user) }

    it 'shows orders list' do
      get admin_orders_path
      expect(response).to have_http_status(:ok)
    end

    it 'displays statistics' do
      get admin_orders_path
      expect(response.body).to include('Всего заказов')
      expect(response.body).to include('Выручка')
    end

    it 'displays all orders' do
      get admin_orders_path
      orders.each do |order|
        expect(response.body).to include(order.order_number)
      end
    end

    context 'with status filter' do
      let!(:paid_order) { create(:order, user: user, status: :paid) }

      it 'filters by status' do
        get admin_orders_path, params: { status: 'paid' }
        expect(response.body).to include(paid_order.order_number)
      end
    end

    context 'with search' do
      let!(:order) { create(:order, user: user, order_number: 'BR-2026-TEST') }

      it 'searches by order number' do
        get admin_orders_path, params: { search: 'TEST' }
        expect(response.body).to include('BR-2026-TEST')
      end

      it 'searches by user email' do
        get admin_orders_path, params: { search: user.email }
        expect(response.body).to include(user.email)
      end
    end

    context 'with date filters' do
      let!(:old_order) { create(:order, user: user, created_at: 10.days.ago) }
      let!(:new_order) { create(:order, user: user, created_at: 1.day.ago) }

      it 'filters by date from' do
        get admin_orders_path, params: { date_from: 2.days.ago.to_date }
        expect(response.body).to include(new_order.order_number)
        expect(response.body).not_to include(old_order.order_number)
      end
    end
  end

  describe 'GET /admin/orders/:id' do
    let(:product) { create(:product, :published) }
    let(:order) { create(:order, user: user) }
    let!(:order_item) { create(:order_item, order: order, product: product) }

    it 'shows order details' do
      get admin_order_path(order)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(order.order_number)
    end

    it 'displays order items' do
      get admin_order_path(order)
      expect(response.body).to include(product.name)
    end

    it 'displays customer info' do
      get admin_order_path(order)
      expect(response.body).to include(user.email)
    end
  end

  describe 'PATCH /admin/orders/:id' do
    context 'complete action' do
      let(:paid_order) { create(:order, user: user, status: :paid) }

      it 'completes the order' do
        patch admin_order_path(paid_order), params: { order_action: 'complete' }

        expect(response).to redirect_to(admin_order_path(paid_order))
        expect(paid_order.reload.status).to eq('completed')
      end
    end

    context 'refund action' do
      let(:paid_order) { create(:order, user: user, status: :paid) }

      it 'refunds the order' do
        patch admin_order_path(paid_order), params: { order_action: 'refund' }

        expect(response).to redirect_to(admin_order_path(paid_order))
        expect(paid_order.reload.status).to eq('refunded')
      end
    end

    context 'cancel action' do
      let(:pending_order) { create(:order, user: user, status: :pending) }

      it 'cancels the order' do
        patch admin_order_path(pending_order), params: { order_action: 'cancel' }

        expect(response).to redirect_to(admin_order_path(pending_order))
        expect(pending_order.reload.status).to eq('cancelled')
      end
    end

    context 'invalid transition' do
      let(:completed_order) { create(:order, user: user, status: :completed) }

      it 'shows error for invalid transition' do
        patch admin_order_path(completed_order), params: { order_action: 'cancel' }

        expect(response).to redirect_to(admin_order_path(completed_order))
        expect(flash[:alert]).to include('Невозможно')
      end
    end
  end
end
