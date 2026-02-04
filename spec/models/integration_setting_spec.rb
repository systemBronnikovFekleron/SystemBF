# frozen_string_literal: true

require 'rails_helper'

RSpec.describe IntegrationSetting, type: :model do
  # Associations
  describe 'associations' do
    it { should belong_to(:created_by).class_name('User').optional }
    it { should belong_to(:updated_by).class_name('User').optional }
    it { should have_many(:integration_logs).dependent(:destroy) }
    it { should have_many(:integration_statistics).dependent(:destroy) }
  end

  # Validations
  describe 'validations' do
    subject { build(:integration_setting) }

    it { should validate_presence_of(:integration_type) }
    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:integration_type) }
    it do
      should validate_inclusion_of(:integration_type)
        .in_array(%w[email telegram google_analytics cloudpayments])
    end

    it do
      should validate_inclusion_of(:last_test_status)
        .in_array(%w[success failed pending])
        .allow_nil
    end
  end

  # Scopes
  describe 'scopes' do
    let!(:enabled_setting) { create(:integration_setting, :email, :enabled) }
    let!(:disabled_setting) { create(:integration_setting, :telegram, :disabled) }
    let!(:healthy_setting) { create(:integration_setting, :google_analytics, :healthy) }
    let!(:unhealthy_setting) { create(:integration_setting, :cloudpayments, :unhealthy) }

    describe '.enabled' do
      it 'returns only enabled settings' do
        expect(described_class.enabled).to include(enabled_setting)
        expect(described_class.enabled).not_to include(disabled_setting)
      end
    end

    describe '.disabled' do
      it 'returns only disabled settings' do
        expect(described_class.disabled).to include(disabled_setting)
        expect(described_class.disabled).not_to include(enabled_setting)
      end
    end

    describe '.healthy' do
      it 'returns only healthy settings' do
        expect(described_class.healthy).to include(healthy_setting)
        expect(described_class.healthy).not_to include(unhealthy_setting)
      end
    end

    describe '.unhealthy' do
      it 'returns only unhealthy settings' do
        expect(described_class.unhealthy).to include(unhealthy_setting)
        expect(described_class.unhealthy).not_to include(healthy_setting)
      end
    end
  end

  # Instance methods
  describe '#enable!' do
    let(:setting) { create(:integration_setting, :email, :disabled) }

    it 'enables the integration' do
      expect { setting.enable! }.to change { setting.enabled }.from(false).to(true)
    end

    it 'creates a log entry' do
      expect { setting.enable! }.to change { setting.integration_logs.count }.by(1)
      log = setting.integration_logs.last
      expect(log.event_type).to eq('integration_enabled')
      expect(log.status).to eq('success')
    end
  end

  describe '#disable!' do
    let(:setting) { create(:integration_setting, :telegram, :enabled) }

    it 'disables the integration' do
      expect { setting.disable! }.to change { setting.enabled }.from(true).to(false)
    end

    it 'creates a log entry' do
      expect { setting.disable! }.to change { setting.integration_logs.count }.by(1)
      log = setting.integration_logs.last
      expect(log.event_type).to eq('integration_disabled')
      expect(log.status).to eq('success')
    end
  end

  describe '#healthy?' do
    it 'returns true for recent successful test' do
      setting = create(:integration_setting, :email, :healthy)
      expect(setting.healthy?).to be true
    end

    it 'returns false for failed test' do
      setting = create(:integration_setting, :telegram, :unhealthy)
      expect(setting.healthy?).to be false
    end

    it 'returns false for old successful test' do
      setting = create(:integration_setting, :google_analytics,
                       last_test_status: 'success',
                       last_test_at: 2.days.ago)
      expect(setting.healthy?).to be false
    end

    it 'returns false when test was never run' do
      setting = create(:integration_setting, :cloudpayments)
      expect(setting.healthy?).to be false
    end
  end

  describe '#credentials_hash' do
    let(:credentials) { { api_key: 'secret123', api_secret: 'secret456' } }
    let(:setting) do
      create(:integration_setting, integration_type: 'email',
                                    encrypted_credentials: credentials.to_json)
    end

    it 'returns parsed credentials as hash with indifferent access' do
      result = setting.credentials_hash
      expect(result[:api_key]).to eq('secret123')
      expect(result['api_key']).to eq('secret123')
    end

    it 'returns empty hash when credentials are blank' do
      setting.update_column(:encrypted_credentials, nil)
      expect(setting.credentials_hash).to eq({})
    end

    it 'caches the result' do
      expect(Rails.cache).to receive(:fetch)
        .with("integration_#{setting.id}/credentials", expires_in: 5.minutes)
        .and_call_original
      setting.credentials_hash
    end
  end

  describe '#update_credentials!' do
    let(:setting) { create(:integration_setting, :email) }
    let(:new_credentials) { { api_key: 'new_secret', api_secret: 'new_secret2' } }

    it 'updates encrypted credentials' do
      setting.update_credentials!(new_credentials)
      expect(setting.credentials_hash[:api_key]).to eq('new_secret')
    end

    it 'creates a log entry' do
      expect { setting.update_credentials!(new_credentials) }
        .to change { setting.integration_logs.count }.by(1)
      log = setting.integration_logs.last
      expect(log.event_type).to eq('credentials_updated')
    end
  end

  describe '#increment_usage!' do
    let(:setting) { create(:integration_setting, :email) }

    it 'increments usage count' do
      expect { setting.increment_usage! }
        .to change { setting.reload.usage_count }.by(1)
    end

    it 'updates last_used_at' do
      expect { setting.increment_usage! }
        .to change { setting.reload.last_used_at }
    end
  end

  describe '#masked_credentials' do
    let(:credentials) { { api_key: 'secret123456', short: 'abc' } }
    let(:setting) do
      create(:integration_setting, integration_type: 'telegram',
                                    encrypted_credentials: credentials.to_json)
    end

    it 'masks long credentials' do
      result = setting.masked_credentials
      expect(result[:api_key]).to eq('secr...456')
    end

    it 'does not mask short credentials' do
      result = setting.masked_credentials
      expect(result[:short]).to eq('abc')
    end

    it 'returns empty hash when no credentials' do
      setting.update_column(:encrypted_credentials, nil)
      expect(setting.masked_credentials).to eq({})
    end
  end

  describe 'encryption' do
    let(:credentials) { { api_key: 'secret123', api_secret: 'secret456' } }
    let(:setting) do
      create(:integration_setting, integration_type: 'google_analytics',
                                    encrypted_credentials: credentials.to_json)
    end

    it 'encrypts credentials in database' do
      raw_value = ActiveRecord::Base.connection.execute(
        "SELECT encrypted_credentials FROM integration_settings WHERE id = #{setting.id}"
      ).first['encrypted_credentials']

      expect(raw_value).not_to include('secret123')
      expect(raw_value).not_to include('secret456')
    end

    it 'decrypts credentials when accessed' do
      setting.reload
      expect(setting.credentials_hash[:api_key]).to eq('secret123')
    end
  end

  describe 'cache clearing' do
    let(:setting) { create(:integration_setting, :email) }

    it 'clears cache when credentials are updated' do
      setting.credentials_hash # populate cache
      expect(Rails.cache).to receive(:delete).with("integration_#{setting.id}/credentials")
      setting.update(encrypted_credentials: { new: 'value' }.to_json)
    end
  end
end
