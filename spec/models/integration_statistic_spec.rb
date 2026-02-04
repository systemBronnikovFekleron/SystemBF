# frozen_string_literal: true

require 'rails_helper'

RSpec.describe IntegrationStatistic, type: :model do
  # Associations
  describe 'associations' do
    it { should belong_to(:integration_setting) }
  end

  # Validations
  describe 'validations' do
    subject { build(:integration_statistic) }

    it { should validate_presence_of(:date) }
    it { should validate_presence_of(:period_type) }
    it { should validate_inclusion_of(:period_type).in_array(%w[daily weekly monthly]) }
    it do
      should validate_uniqueness_of(:date)
        .scoped_to([:integration_setting_id, :period_type])
    end
  end

  # Scopes
  describe 'scopes' do
    let(:setting) { create(:integration_setting, :email) }
    let!(:daily_stat) { create(:integration_statistic, :daily, integration_setting: setting) }
    let!(:weekly_stat) { create(:integration_statistic, :weekly, integration_setting: setting) }
    let!(:monthly_stat) { create(:integration_statistic, :monthly, integration_setting: setting) }
    let!(:old_stat) do
      create(:integration_statistic, integration_setting: setting, date: 2.months.ago)
    end

    it '.daily returns only daily statistics' do
      expect(described_class.daily).to include(daily_stat)
      expect(described_class.daily).not_to include(weekly_stat)
    end

    it '.weekly returns only weekly statistics' do
      expect(described_class.weekly).to include(weekly_stat)
      expect(described_class.weekly).not_to include(daily_stat)
    end

    it '.monthly returns only monthly statistics' do
      expect(described_class.monthly).to include(monthly_stat)
      expect(described_class.monthly).not_to include(daily_stat)
    end

    it '.for_period filters by date range' do
      results = described_class.for_period(1.month.ago, Date.current)
      expect(results).to include(daily_stat)
      expect(results).not_to include(old_stat)
    end

    it '.recent limits and orders by date desc' do
      expect(described_class.recent(2).count).to eq(2)
      expect(described_class.recent.first).to eq(daily_stat)
    end
  end

  # Callbacks
  describe 'callbacks' do
    it 'calculates success_rate before save' do
      stat = build(:integration_statistic, total_requests: 100, successful_requests: 95)
      stat.save
      expect(stat.success_rate).to eq(95.0)
    end
  end

  # Instance methods
  describe '#success_rate_percentage' do
    it 'calculates percentage correctly' do
      stat = build(:integration_statistic, total_requests: 100, successful_requests: 95)
      expect(stat.success_rate_percentage).to eq(95.0)
    end

    it 'returns 0 when no requests' do
      stat = build(:integration_statistic, :no_requests)
      expect(stat.success_rate_percentage).to eq(0)
    end

    it 'rounds to 2 decimal places' do
      stat = build(:integration_statistic, total_requests: 3, successful_requests: 2)
      expect(stat.success_rate_percentage).to eq(66.67)
    end
  end

  describe '#failure_rate_percentage' do
    it 'calculates failure percentage correctly' do
      stat = build(:integration_statistic, total_requests: 100, failed_requests: 5)
      expect(stat.failure_rate_percentage).to eq(5.0)
    end

    it 'returns 0 when no requests' do
      stat = build(:integration_statistic, :no_requests)
      expect(stat.failure_rate_percentage).to eq(0)
    end
  end

  describe '#avg_duration_seconds' do
    it 'converts milliseconds to seconds' do
      stat = build(:integration_statistic, avg_duration_ms: 2500)
      expect(stat.avg_duration_seconds).to eq(2.5)
    end

    it 'returns nil when avg_duration_ms is nil' do
      stat = build(:integration_statistic, avg_duration_ms: nil)
      expect(stat.avg_duration_seconds).to be_nil
    end
  end

  # Class methods
  describe '.aggregate_from_logs' do
    let(:setting) { create(:integration_setting, :telegram) }
    let(:date) { Date.current }

    before do
      create_list(:integration_log, 10, :success, integration_setting: setting,
                                                   created_at: date, duration_ms: 100)
      create_list(:integration_log, 2, :failed, integration_setting: setting,
                                                 created_at: date, duration_ms: 200)
    end

    it 'aggregates daily statistics from logs' do
      stat = described_class.aggregate_from_logs(setting.id, date, 'daily')
      expect(stat.total_requests).to eq(12)
      expect(stat.successful_requests).to eq(10)
      expect(stat.failed_requests).to eq(2)
      expect(stat.avg_duration_ms).to be_within(10).of(116)
    end

    it 'creates or updates existing statistic' do
      expect do
        described_class.aggregate_from_logs(setting.id, date, 'daily')
      end.to change { described_class.count }.by(1)

      expect do
        described_class.aggregate_from_logs(setting.id, date, 'daily')
      end.not_to change { described_class.count }
    end
  end
end
