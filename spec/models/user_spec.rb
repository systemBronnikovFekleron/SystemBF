# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  subject { build(:user) }

  describe 'associations' do
    it { should have_one(:profile).dependent(:destroy) }
    it { should have_one(:wallet).dependent(:destroy) }
    it { should have_one(:rating).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
    it { should validate_length_of(:password).is_at_least(8) }
  end

  describe 'enums' do
    it do
      should define_enum_for(:classification)
        .with_values(
          guest: 0,
          client: 1,
          club_member: 2,
          representative: 3,
          trainee: 4,
          instructor_1: 5,
          instructor_2: 6,
          instructor_3: 7,
          specialist: 8,
          expert: 9,
          center_director: 10,
          curator: 11,
          manager: 12,
          admin: 13
        )
        .with_prefix(true)
    end
  end

  describe 'callbacks' do
    let(:user) { build(:user, email: 'TEST@EXAMPLE.COM') }

    it 'normalizes email before save' do
      user.save
      expect(user.email).to eq('test@example.com')
    end

    it 'creates associated records after create' do
      user.save
      expect(user.profile).to be_present
      expect(user.wallet).to be_present
      expect(user.rating).to be_present
    end
  end

  describe '#classification' do
    it 'defaults to guest' do
      user = User.new(email: 'test@example.com', password: 'password123')
      expect(user.classification).to eq('guest')
    end

    it 'can be set to admin' do
      user = create(:user, :admin)
      expect(user.classification_admin?).to be true
    end
  end

  describe 'password reset methods' do
    let(:user) { create(:user) }

    describe '#create_reset_password_token!' do
      it 'generates a reset token' do
        user.create_reset_password_token!

        expect(user.reset_password_token).to be_present
        expect(user.reset_password_token.length).to be >= 32
      end

      it 'sets reset_password_sent_at to current time' do
        freeze_time do
          user.create_reset_password_token!
          expect(user.reset_password_sent_at).to be_within(1.second).of(Time.current)
        end
      end

      it 'saves the user' do
        expect {
          user.create_reset_password_token!
        }.to change { user.reload.reset_password_token }.from(nil)
      end
    end

    describe '#reset_password_token_expired?' do
      context 'when token was sent less than 24 hours ago' do
        before do
          user.create_reset_password_token!
        end

        it 'returns false' do
          expect(user.reset_password_token_expired?).to be false
        end
      end

      context 'when token was sent exactly 24 hours ago' do
        before do
          user.create_reset_password_token!
          user.update_column(:reset_password_sent_at, 24.hours.ago)
        end

        it 'returns false' do
          expect(user.reset_password_token_expired?).to be false
        end
      end

      context 'when token was sent more than 24 hours ago' do
        before do
          user.create_reset_password_token!
          user.update_column(:reset_password_sent_at, 25.hours.ago)
        end

        it 'returns true' do
          expect(user.reset_password_token_expired?).to be true
        end
      end

      context 'when reset_password_sent_at is nil' do
        it 'returns true' do
          expect(user.reset_password_token_expired?).to be true
        end
      end
    end

    describe '#clear_reset_password_token!' do
      before do
        user.create_reset_password_token!
      end

      it 'clears reset_password_token' do
        user.clear_reset_password_token!
        expect(user.reset_password_token).to be_nil
      end

      it 'clears reset_password_sent_at' do
        user.clear_reset_password_token!
        expect(user.reset_password_sent_at).to be_nil
      end

      it 'saves the user' do
        expect {
          user.clear_reset_password_token!
        }.to change { user.reload.reset_password_token }.to(nil)
      end
    end
  end

  describe 'SubRole methods' do
    let(:user) { create(:user) }
    let(:client_role) { SubRole.find_or_create_by!(name: 'client', display_name: 'Клиент', level: 1, system_role: true) }
    let(:instructor_role) { SubRole.find_or_create_by!(name: 'instructor_1', display_name: 'Инструктор 1', level: 5, system_role: true) }

    describe '#grant_sub_role!' do
      it 'grants a role to user by id' do
        expect { user.grant_sub_role!(client_role.id) }.to change { user.sub_roles.count }.by(1)
        expect(user.has_sub_role?(client_role.id)).to be true
      end

      it 'grants a role to user by name' do
        expect { user.grant_sub_role!('client') }.to change { user.sub_roles.count }.by(1)
        expect(user.has_sub_role?('client')).to be true
      end

      it 'does not raise error when granting duplicate role' do
        user.grant_sub_role!(client_role.id)
        expect { user.grant_sub_role!(client_role.id) }.not_to raise_error
      end

      it 'records granted_by when specified' do
        admin = create(:user, :admin)
        user.grant_sub_role!(client_role.id, granted_by: admin)
        user_sub_role = user.user_sub_roles.last
        expect(user_sub_role.granted_by).to eq(admin)
      end

      it 'records granted_via when specified' do
        user.grant_sub_role!(client_role.id, granted_via: 'product_purchase')
        user_sub_role = user.user_sub_roles.last
        expect(user_sub_role.granted_via).to eq('product_purchase')
      end
    end

    describe '#grant_sub_roles!' do
      it 'grants multiple roles by ids' do
        expect {
          user.grant_sub_roles!([client_role.id, instructor_role.id])
        }.to change { user.sub_roles.count }.by(2)
      end

      it 'grants multiple roles by names' do
        expect {
          user.grant_sub_roles!(['client', 'instructor_1'])
        }.to change { user.sub_roles.count }.by(2)
      end
    end

    describe '#has_sub_role?' do
      before { user.grant_sub_role!(client_role.id) }

      it 'returns true for granted role by id' do
        expect(user.has_sub_role?(client_role.id)).to be true
      end

      it 'returns true for granted role by name' do
        expect(user.has_sub_role?('client')).to be true
      end

      it 'returns false for not granted role' do
        expect(user.has_sub_role?('instructor_1')).to be false
      end
    end

    describe '#has_any_sub_role?' do
      before { user.grant_sub_role!(client_role.id) }

      it 'returns true when user has any of specified roles' do
        expect(user.has_any_sub_role?(['client', 'instructor_1'])).to be true
      end

      it 'returns false when user has none of specified roles' do
        expect(user.has_any_sub_role?(['instructor_1', 'specialist'])).to be false
      end

      it 'returns false for empty array' do
        expect(user.has_any_sub_role?([])).to be false
      end

      it 'works with role ids' do
        expect(user.has_any_sub_role?([client_role.id, instructor_role.id])).to be true
      end
    end

    describe '#active_sub_roles' do
      it 'returns only active roles' do
        user.grant_sub_role!(client_role.id)
        UserSubRole.create!(
          user: user,
          sub_role: instructor_role,
          granted_at: 2.days.ago,
          expires_at: 1.day.ago
        )
        expect(user.active_sub_roles).to include(client_role)
        expect(user.active_sub_roles).not_to include(instructor_role)
      end
    end
  end
end
