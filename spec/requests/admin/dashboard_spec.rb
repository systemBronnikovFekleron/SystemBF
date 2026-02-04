# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin::Dashboard', type: :request do
  let(:admin) { create(:user, :admin) }

  before { sign_in(admin) }

  describe 'GET /admin' do
    it 'shows dashboard' do
      get admin_root_path
      expect(response).to have_http_status(:ok)
    end

    it 'displays statistics' do
      create_list(:product, 3, :published)
      create_list(:user, 5)
      create_list(:order, 2, user: create(:user), status: :paid)

      get admin_root_path

      expect(response.body).to include('Продукты')
      expect(response.body).to include('Клиенты')
      expect(response.body).to include('Заказы')
      expect(response.body).to include('Выручка')
    end

    context 'with revenue data' do
      before do
        user = create(:user)
        create_list(:order, 3, user: user, status: :paid, total_kopecks: 100_000)
      end

      it 'displays revenue chart' do
        get admin_root_path
        expect(response.body).to include('Выручка за 30 дней')
      end

      it 'includes chart data' do
        get admin_root_path
        expect(response.body).to include('data-controller="chart"')
      end
    end

    context 'with top products' do
      let(:user) { create(:user) }
      let(:product) { create(:product, :published, name: 'Топ продукт') }

      before do
        order = create(:order, user: user, status: :paid)
        create(:order_item, order: order, product: product, price_kopecks: 500_000)
      end

      it 'displays top products chart' do
        get admin_root_path
        expect(response.body).to include('Топ-10 продуктов')
      end
    end

    it 'displays users by classification' do
      create(:user, :client)
      create(:user, :specialist)
      create(:user, :admin)

      get admin_root_path
      expect(response.body).to include('Пользователи по типу')
    end

    it 'displays recent orders' do
      user = create(:user)
      order = create(:order, user: user)

      get admin_root_path
      expect(response.body).to include('Последние заказы')
      expect(response.body).to include(order.order_number)
    end

    it 'displays recent users' do
      user = create(:user, email: 'new@example.com')

      get admin_root_path
      expect(response.body).to include('Новые пользователи')
      expect(response.body).to include(user.email)
    end
  end
end
