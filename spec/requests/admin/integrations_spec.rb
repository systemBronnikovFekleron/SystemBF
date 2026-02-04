# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin::Integrations', type: :request do
  let(:admin) { create(:user, classification: :admin) }
  let(:regular_user) { create(:user, classification: :client) }
  let(:integration) { create(:integration_setting, :email, :enabled) }

  describe 'GET /admin/integrations' do
    context 'as admin' do
      before { sign_in admin }

      it 'returns success' do
        get admin_integrations_path
        expect(response).to have_http_status(:success)
      end

      it 'displays all integrations' do
        create(:integration_setting, :email)
        create(:integration_setting, :telegram)
        get admin_integrations_path
        expect(response.body).to include('Email Integration')
        expect(response.body).to include('Telegram Bot')
      end
    end

    context 'as regular user' do
      before { sign_in regular_user }

      it 'denies access' do
        get admin_integrations_path
        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to include('нет прав')
      end
    end

    context 'as guest' do
      it 'redirects to login' do
        get admin_integrations_path
        expect(response).to redirect_to(login_path)
      end
    end
  end

  describe 'GET /admin/integrations/:id' do
    before { sign_in admin }

    it 'returns success' do
      get admin_integration_path(integration)
      expect(response).to have_http_status(:success)
    end

    it 'displays integration details' do
      get admin_integration_path(integration)
      expect(response.body).to include(integration.name)
    end

    it 'displays recent logs' do
      create_list(:integration_log, 5, integration_setting: integration)
      get admin_integration_path(integration)
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET /admin/integrations/:id/edit' do
    before { sign_in admin }

    it 'returns success' do
      get edit_admin_integration_path(integration)
      expect(response).to have_http_status(:success)
    end

    it 'displays edit form' do
      get edit_admin_integration_path(integration)
      expect(response.body).to include('form')
      expect(response.body).to include(integration.name)
    end
  end

  describe 'PATCH /admin/integrations/:id' do
    before { sign_in admin }

    context 'with valid params' do
      let(:valid_params) do
        {
          integration_setting: {
            name: 'Updated Name',
            description: 'Updated description',
            settings: { key: 'value' }
          }
        }
      end

      it 'updates the integration' do
        patch admin_integration_path(integration), params: valid_params
        integration.reload
        expect(integration.name).to eq('Updated Name')
        expect(integration.description).to eq('Updated description')
      end

      it 'redirects to show page' do
        patch admin_integration_path(integration), params: valid_params
        expect(response).to redirect_to(admin_integration_path(integration))
      end

      it 'displays success notice' do
        patch admin_integration_path(integration), params: valid_params
        follow_redirect!
        expect(response.body).to include('успешно обновлены')
      end
    end

    context 'with credentials update' do
      let(:credentials_params) do
        {
          integration_setting: {
            credentials: {
              smtp_address: 'smtp.newhost.com',
              smtp_port: '587',
              smtp_user_name: 'user@newhost.com',
              smtp_password: 'newpassword'
            }
          }
        }
      end

      it 'updates encrypted credentials' do
        expect do
          patch admin_integration_path(integration), params: credentials_params
        end.to change { integration.reload.credentials_hash[:smtp_address] }.to('smtp.newhost.com')
      end

      it 'creates a log entry' do
        expect do
          patch admin_integration_path(integration), params: credentials_params
        end.to change { integration.integration_logs.count }.by(1)
      end
    end
  end

  describe 'POST /admin/integrations/:id/test_connection' do
    before { sign_in admin }

    context 'when test succeeds' do
      before do
        allow_any_instance_of(IntegrationSetting).to receive(:test_connection)
          .and_return({ success: true, message: 'Connection successful' })
      end

      it 'displays success message' do
        post test_connection_admin_integration_path(integration)
        follow_redirect!
        expect(response.body).to include('Connection successful')
      end

      it 'updates last_test_at' do
        expect do
          post test_connection_admin_integration_path(integration)
        end.to change { integration.reload.last_test_at }
      end
    end

    context 'when test fails' do
      before do
        allow_any_instance_of(IntegrationSetting).to receive(:test_connection)
          .and_return({ success: false, message: 'Connection failed' })
      end

      it 'displays error message' do
        post test_connection_admin_integration_path(integration)
        follow_redirect!
        expect(response.body).to include('Connection failed')
      end
    end
  end

  describe 'POST /admin/integrations/:id/toggle_status' do
    before { sign_in admin }

    context 'when integration is enabled' do
      let(:integration) { create(:integration_setting, :email, :enabled) }

      it 'disables the integration' do
        expect do
          post toggle_status_admin_integration_path(integration)
        end.to change { integration.reload.enabled }.from(true).to(false)
      end

      it 'displays success message' do
        post toggle_status_admin_integration_path(integration)
        follow_redirect!
        expect(response.body).to include('отключена')
      end
    end

    context 'when integration is disabled' do
      let(:integration) { create(:integration_setting, :email, enabled: false) }

      it 'enables the integration' do
        expect do
          post toggle_status_admin_integration_path(integration)
        end.to change { integration.reload.enabled }.from(false).to(true)
      end

      it 'displays success message' do
        post toggle_status_admin_integration_path(integration)
        follow_redirect!
        expect(response.body).to include('включена')
      end
    end
  end

  describe 'GET /admin/integrations/:id/logs' do
    before { sign_in admin }

    it 'returns success' do
      get logs_admin_integration_path(integration)
      expect(response).to have_http_status(:success)
    end

    it 'displays logs' do
      create_list(:integration_log, 3, integration_setting: integration)
      get logs_admin_integration_path(integration)
      expect(response).to have_http_status(:success)
    end

    it 'filters by status' do
      create(:integration_log, :success, integration_setting: integration)
      create(:integration_log, :failed, integration_setting: integration)

      get logs_admin_integration_path(integration), params: { status: 'success' }
      expect(response).to have_http_status(:success)
    end

    it 'paginates results' do
      create_list(:integration_log, 60, integration_setting: integration)
      get logs_admin_integration_path(integration), params: { page: 2 }
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET /admin/integrations/:id/statistics' do
    before { sign_in admin }

    it 'returns success' do
      get statistics_admin_integration_path(integration)
      expect(response).to have_http_status(:success)
    end

    it 'displays daily statistics by default' do
      create_list(:integration_statistic, 10, :daily, integration_setting: integration)
      get statistics_admin_integration_path(integration)
      expect(response).to have_http_status(:success)
    end

    it 'allows filtering by period' do
      create_list(:integration_statistic, 5, :weekly, integration_setting: integration)
      get statistics_admin_integration_path(integration), params: { period: 'weekly' }
      expect(response).to have_http_status(:success)
    end
  end
end
