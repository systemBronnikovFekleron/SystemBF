# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Dashboard', type: :request do
  let(:user) { create(:user, :client) }

  before { sign_in(user) }

  describe 'GET /dashboard' do
    it 'shows dashboard index' do
      get dashboard_path
      expect(response).to have_http_status(:ok)
    end

    it 'displays user stats' do
      create_list(:order, 3, user: user, status: :paid)
      create_list(:product_access, 2, user: user)

      get dashboard_path
      expect(response.body).to include('Обзор')
    end
  end

  describe 'GET /dashboard/profile' do
    it 'shows user profile' do
      get dashboard_profile_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(user.email)
    end
  end

  describe 'PATCH /dashboard/profile' do
    context 'with valid params' do
      let(:valid_params) do
        {
          profile: {
            first_name: 'Иван',
            last_name: 'Иванов',
            phone: '+79991234567',
            city: 'Москва'
          }
        }
      end

      it 'updates profile' do
        patch dashboard_profile_path, params: valid_params
        expect(response).to redirect_to(dashboard_profile_path)
        expect(user.profile.reload.first_name).to eq('Иван')
      end
    end
  end

  describe 'GET /dashboard/wallet' do
    it 'shows wallet page' do
      get dashboard_wallet_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Кошелек')
    end

    it 'displays current balance' do
      user.wallet.update(balance_kopecks: 500_000) # 5000 руб
      get dashboard_wallet_path
      expect(response.body).to include('5')
    end
  end

  describe 'POST /dashboard/wallet/deposit' do
    context 'with valid amount' do
      it 'creates order and redirects to payment' do
        post deposit_wallet_path, params: { amount: 1000 }

        order = Order.last
        expect(order.user).to eq(user)
        expect(order.total_kopecks).to eq(100_000)
        expect(response).to redirect_to(new_order_payment_path(order))
      end
    end

    context 'with invalid amount' do
      it 'rejects amount below minimum' do
        post deposit_wallet_path, params: { amount: 50 }
        expect(response).to redirect_to(dashboard_wallet_path)
        expect(flash[:alert]).to include('Минимальная сумма')
      end
    end
  end

  describe 'GET /dashboard/my-courses' do
    it 'shows user courses' do
      product_access = create(:product_access, user: user)

      get dashboard_my_courses_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(product_access.product.name)
    end

    it 'shows empty state when no courses' do
      get dashboard_my_courses_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Нет активных курсов')
    end
  end

  describe 'GET /dashboard/achievements' do
    it 'shows achievements page' do
      get dashboard_achievements_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Достижения')
    end
  end

  describe 'GET /dashboard/notifications' do
    it 'shows notifications page' do
      get dashboard_notifications_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Уведомления')
    end
  end

  describe 'GET /dashboard/settings' do
    it 'shows settings page' do
      get dashboard_settings_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Настройки')
    end
  end

  describe 'GET /dashboard/rating' do
    it 'shows rating page' do
      get dashboard_rating_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Рейтинг')
    end

    it 'displays leaderboard' do
      create_list(:user, 5, :client)

      get dashboard_rating_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Таблица лидеров')
    end
  end

  describe 'GET /dashboard/orders' do
    it 'shows user orders' do
      order = create(:order, user: user)

      get dashboard_orders_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(order.order_number)
    end
  end

  context 'when not signed in' do
    before { cookies.delete(:jwt_token) }

    it 'redirects to login' do
      get dashboard_path
      expect(response).to redirect_to(login_path)
    end
  end
end
