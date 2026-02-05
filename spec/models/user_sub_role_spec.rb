# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserSubRole, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:sub_role) }
    it { should belong_to(:granted_by).class_name('User').optional }
    it { should belong_to(:source).optional }
  end

  describe 'validations' do
    let(:user) { create(:user) }
    let(:role) { SubRole.find_or_create_by!(name: 'client', display_name: 'Клиент', level: 1, system_role: true) }

    it 'validates uniqueness of user_id scoped to sub_role_id' do
      UserSubRole.create!(user: user, sub_role: role, granted_at: Time.current)
      duplicate = UserSubRole.new(user: user, sub_role: role, granted_at: Time.current)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:user_id]).to include('уже существует')
    end
  end

  describe 'callbacks' do
    it 'sets granted_at on create' do
      user = create(:user)
      role = SubRole.find_or_create_by!(name: 'client', display_name: 'Клиент', level: 1, system_role: true)
      user_sub_role = UserSubRole.create!(user: user, sub_role: role)
      expect(user_sub_role.granted_at).to be_present
    end
  end

  describe 'scopes' do
    let(:user) { create(:user) }
    let(:role) { SubRole.find_or_create_by!(name: 'client', display_name: 'Клиент', level: 1, system_role: true) }

    describe '.active' do
      it 'includes roles without expiry' do
        active_role = UserSubRole.create!(user: user, sub_role: role, granted_at: Time.current)
        expect(UserSubRole.active).to include(active_role)
      end

      it 'includes roles with future expiry' do
        active_role = UserSubRole.create!(
          user: user,
          sub_role: role,
          granted_at: Time.current,
          expires_at: 1.day.from_now
        )
        expect(UserSubRole.active).to include(active_role)
      end

      it 'excludes expired roles' do
        expired_role = UserSubRole.create!(
          user: user,
          sub_role: role,
          granted_at: 2.days.ago,
          expires_at: 1.day.ago
        )
        expect(UserSubRole.active).not_to include(expired_role)
      end
    end
  end

  describe '#active?' do
    let(:user) { create(:user) }
    let(:role) { SubRole.find_or_create_by!(name: 'client', display_name: 'Клиент', level: 1, system_role: true) }

    it 'returns true for roles without expiry' do
      user_sub_role = UserSubRole.create!(user: user, sub_role: role, granted_at: Time.current)
      expect(user_sub_role.active?).to be true
    end

    it 'returns true for roles with future expiry' do
      user_sub_role = UserSubRole.create!(
        user: user,
        sub_role: role,
        granted_at: Time.current,
        expires_at: 1.day.from_now
      )
      expect(user_sub_role.active?).to be true
    end

    it 'returns false for expired roles' do
      user_sub_role = UserSubRole.create!(
        user: user,
        sub_role: role,
        granted_at: 2.days.ago,
        expires_at: 1.day.ago
      )
      expect(user_sub_role.active?).to be false
    end
  end
end
