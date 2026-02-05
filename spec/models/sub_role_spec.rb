# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SubRole, type: :model do
  describe 'associations' do
    it { should have_many(:user_sub_roles).dependent(:destroy) }
    it { should have_many(:users).through(:user_sub_roles) }
    it { should have_many(:content_sub_roles).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:display_name) }

    it 'validates uniqueness of name' do
      create(:sub_role, :system)
      should validate_uniqueness_of(:name)
    end
  end

  describe 'scopes' do
    let!(:system_role) { SubRole.find_or_create_by!(name: 'client', display_name: 'Клиент', level: 1, system_role: true) }
    let!(:custom_role) { create(:sub_role) }

    describe '.system_roles' do
      it 'returns only system roles' do
        expect(SubRole.system_roles).to include(system_role)
        expect(SubRole.system_roles).not_to include(custom_role)
      end
    end

    describe '.custom_roles' do
      it 'returns only custom roles' do
        expect(SubRole.custom_roles).to include(custom_role)
        expect(SubRole.custom_roles).not_to include(system_role)
      end
    end

    describe '.ordered' do
      it 'orders by level then name' do
        roles = SubRole.ordered
        expect(roles.first.level).to be <= roles.last.level
      end
    end
  end

  describe '#users_count' do
    it 'returns count of users with this role' do
      role = SubRole.find_or_create_by!(name: 'client', display_name: 'Клиент', level: 1, system_role: true)
      user = create(:user)
      user.grant_sub_role!(role.id)

      expect(role.users_count).to eq(1)
    end
  end

  describe '#content_count' do
    it 'returns count of content with this role' do
      role = SubRole.find_or_create_by!(name: 'client', display_name: 'Клиент', level: 1, system_role: true)
      product = create(:product, :published)
      product.add_required_roles([role.id])

      expect(role.content_count).to eq(1)
    end
  end
end
