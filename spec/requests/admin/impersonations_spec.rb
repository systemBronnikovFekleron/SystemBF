# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin::Impersonations', type: :request do
  let(:admin) { create(:user, :admin) }
  let(:target_user) { create(:user) }

  before { sign_in(admin) }

  describe 'GET /admin/impersonations' do
    it 'returns success' do
      get admin_impersonations_path
      expect(response).to have_http_status(:success)
    end

    it 'displays active sessions' do
      log = create(:impersonation_log, :active, admin: admin)
      get admin_impersonations_path
      expect(response.body).to include(log.user.email)
    end

    it 'displays statistics' do
      create_list(:impersonation_log, 3, :active, admin: admin)
      get admin_impersonations_path
      expect(response.body).to include('Активные сейчас')
    end
  end

  describe 'POST /admin/impersonations' do
    it 'creates impersonation session' do
      expect {
        post admin_impersonations_path, params: { user_id: target_user.id }
      }.to change { ImpersonationLog.count }.by(1)
    end

    it 'sets JWT token in cookies' do
      post admin_impersonations_path, params: { user_id: target_user.id }
      # Проверяем что cookie установлен через Set-Cookie header
      expect(response.headers['Set-Cookie']).to be_present
      expect(response.headers['Set-Cookie'].to_s).to match(/jwt_token/)
    end

    it 'redirects to dashboard' do
      post admin_impersonations_path, params: { user_id: target_user.id }
      expect(response).to redirect_to(dashboard_path)
    end

    it 'creates log with correct metadata' do
      post admin_impersonations_path, params: { user_id: target_user.id }
      log = ImpersonationLog.last

      expect(log.admin).to eq(admin)
      expect(log.user).to eq(target_user)
      expect(log.session_token).to be_present
      expect(log.ip_address).to eq('127.0.0.1')
    end

    it 'prevents self-impersonation' do
      post admin_impersonations_path, params: { user_id: admin.id }
      expect(response).to redirect_to(admin_user_path(admin))
      expect(flash[:alert]).to include('самого себя')
    end

    it 'prevents admin impersonation' do
      another_admin = create(:user, :admin)
      post admin_impersonations_path, params: { user_id: another_admin.id }
      expect(response).to redirect_to(admin_user_path(another_admin))
      expect(flash[:alert]).to include('другого администратора')
    end

    it 'ends previous active sessions for admin' do
      old_log = create(:impersonation_log, :active, admin: admin)
      post admin_impersonations_path, params: { user_id: target_user.id }

      old_log.reload
      expect(old_log.ended_at).to be_present
    end
  end

  describe 'session ending' do
    it 'ends impersonation session correctly' do
      log = create(:impersonation_log, :active, admin: admin, user: target_user)

      expect(log.active?).to be true
      log.end_session!
      expect(log.active?).to be false
      expect(log.ended_at).to be_present
    end
  end

  describe 'GET /admin/impersonations/:id' do
    let(:log) { create(:impersonation_log, admin: admin, user: target_user) }

    it 'returns success' do
      get admin_impersonation_path(log)
      expect(response).to have_http_status(:success)
    end

    it 'displays session details' do
      get admin_impersonation_path(log)
      expect(response.body).to include(log.admin.email)
      expect(response.body).to include(log.user.email)
    end
  end

  describe 'impersonation flow integration' do
    it 'creates session and allows dashboard access' do
      # Создаем сессию
      post admin_impersonations_path, params: { user_id: target_user.id }
      expect(response).to redirect_to(dashboard_path)

      # Проверяем что сессия создана
      log = ImpersonationLog.last
      expect(log.admin).to eq(admin)
      expect(log.user).to eq(target_user)
      expect(log.active?).to be true
    end
  end
end
