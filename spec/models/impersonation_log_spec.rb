# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ImpersonationLog, type: :model do
  describe 'associations' do
    it { should belong_to(:admin).class_name('User') }
    it { should belong_to(:user).class_name('User') }
  end

  describe 'validations' do
    subject { create(:impersonation_log) }

    it { should validate_uniqueness_of(:session_token) }

    it 'auto-generates session_token before validation' do
      log = ImpersonationLog.new(admin: create(:user, :admin), user: create(:user))
      expect(log.session_token).to be_nil
      log.valid?
      expect(log.session_token).to be_present
    end

    it 'auto-sets started_at before validation' do
      log = ImpersonationLog.new(admin: create(:user, :admin), user: create(:user))
      expect(log.started_at).to be_nil
      log.valid?
      expect(log.started_at).to be_present
    end
  end

  describe 'scopes' do
    let!(:active_log) { create(:impersonation_log, :active) }
    let!(:ended_log) { create(:impersonation_log, :ended) }

    it 'returns active logs' do
      expect(ImpersonationLog.active).to include(active_log)
      expect(ImpersonationLog.active).not_to include(ended_log)
    end

    it 'returns ended logs' do
      expect(ImpersonationLog.ended).to include(ended_log)
      expect(ImpersonationLog.ended).not_to include(active_log)
    end
  end

  describe '#active?' do
    it 'returns true for active non-expired session' do
      log = create(:impersonation_log, :active)
      expect(log.active?).to be true
    end

    it 'returns false for ended session' do
      log = create(:impersonation_log, :ended)
      expect(log.active?).to be false
    end

    it 'returns false for expired session' do
      log = create(:impersonation_log, :expired)
      expect(log.active?).to be false
    end
  end

  describe '#end_session!' do
    it 'sets ended_at timestamp' do
      log = create(:impersonation_log, :active)
      expect { log.end_session! }.to change { log.ended_at }.from(nil)
    end
  end
end
