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
end
