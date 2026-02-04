# frozen_string_literal: true

require 'rails_helper'

RSpec.describe IntegrationLog, type: :model do
  # Associations
  describe 'associations' do
    it { should belong_to(:integration_setting) }
    it { should belong_to(:related).optional }
  end

  # Validations
  describe 'validations' do
    it { should validate_presence_of(:event_type) }
    it { should validate_presence_of(:status) }
    it { should validate_inclusion_of(:status).in_array(%w[success failed pending]) }
  end

  # Scopes
  describe 'scopes' do
    let(:setting) { create(:integration_setting, :email) }
    let!(:success_log) { create(:integration_log, :success, integration_setting: setting) }
    let!(:failed_log) { create(:integration_log, :failed, integration_setting: setting) }
    let!(:old_log) { create(:integration_log, integration_setting: setting, created_at: 35.days.ago) }

    it '.successful returns only successful logs' do
      expect(described_class.successful).to include(success_log)
      expect(described_class.successful).not_to include(failed_log)
    end

    it '.failed returns only failed logs' do
      expect(described_class.failed).to include(failed_log)
      expect(described_class.failed).not_to include(success_log)
    end

    it '.recent orders by created_at desc' do
      expect(described_class.recent.first).to eq(failed_log)
    end

    it '.today returns only today logs' do
      expect(described_class.today).to include(success_log, failed_log)
      expect(described_class.today).not_to include(old_log)
    end

    it '.last_30_days excludes older logs' do
      expect(described_class.last_30_days).to include(success_log)
      expect(described_class.last_30_days).not_to include(old_log)
    end
  end

  # Class methods
  describe '.cleanup_old_logs' do
    let(:setting) { create(:integration_setting, :telegram) }
    let!(:old_log) { create(:integration_log, integration_setting: setting, created_at: 35.days.ago) }
    let!(:recent_log) { create(:integration_log, integration_setting: setting) }

    it 'deletes logs older than specified days' do
      expect { described_class.cleanup_old_logs(30) }
        .to change { described_class.count }.by(-1)
      expect(described_class.exists?(old_log.id)).to be false
      expect(described_class.exists?(recent_log.id)).to be true
    end
  end

  # Instance methods
  describe '#success?' do
    it 'returns true for successful logs' do
      log = build(:integration_log, :success)
      expect(log.success?).to be true
    end

    it 'returns false for failed logs' do
      log = build(:integration_log, :failed)
      expect(log.success?).to be false
    end
  end

  describe '#failed?' do
    it 'returns true for failed logs' do
      log = build(:integration_log, :failed)
      expect(log.failed?).to be true
    end

    it 'returns false for successful logs' do
      log = build(:integration_log, :success)
      expect(log.failed?).to be false
    end
  end

  describe '#duration_seconds' do
    it 'converts milliseconds to seconds' do
      log = build(:integration_log, duration_ms: 1500)
      expect(log.duration_seconds).to eq(1.5)
    end

    it 'returns nil when duration_ms is nil' do
      log = build(:integration_log, duration_ms: nil)
      expect(log.duration_seconds).to be_nil
    end
  end
end
