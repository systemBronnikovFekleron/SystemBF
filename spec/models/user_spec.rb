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
end
