# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EventRegistration, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:event) }
    it { is_expected.to belong_to(:order).optional }
  end

  describe 'validations' do
    subject { build(:event_registration) }

    # Note: registered_at is auto-set by before_validation callback,
    # so presence validation is always satisfied
    it 'requires registered_at after validation' do
      registration = build(:event_registration, registered_at: nil)
      registration.valid?
      expect(registration.registered_at).to be_present
    end

    it 'validates uniqueness of user_id scoped to event_id' do
      event = create(:event)
      user = create(:user)
      create(:event_registration, user: user, event: event)

      duplicate = build(:event_registration, user: user, event: event)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:user_id]).to include('уже зарегистрирован на это событие')
    end

    it 'allows same user to register for different events' do
      user = create(:user)
      event1 = create(:event)
      event2 = create(:event)

      create(:event_registration, user: user, event: event1)
      registration2 = build(:event_registration, user: user, event: event2)

      expect(registration2).to be_valid
    end
  end

  describe 'enums' do
    it { is_expected.to define_enum_for(:status).with_values(pending: 0, confirmed: 1, attended: 2, cancelled: 3).with_prefix(true) }
  end

  describe 'scopes' do
    describe '.ordered' do
      it 'orders by registered_at descending' do
        older = create(:event_registration, registered_at: 2.days.ago)
        newer = create(:event_registration, registered_at: 1.day.ago)

        expect(EventRegistration.ordered.first).to eq(newer)
        expect(EventRegistration.ordered.last).to eq(older)
      end
    end

    describe '.active' do
      it 'excludes cancelled registrations' do
        active = create(:event_registration, status: :confirmed)
        pending = create(:event_registration, status: :pending)
        cancelled = create(:event_registration, status: :cancelled)

        result = EventRegistration.active
        expect(result).to include(active, pending)
        expect(result).not_to include(cancelled)
      end
    end
  end

  describe 'callbacks' do
    describe 'before_validation on create' do
      it 'sets registered_at if not present' do
        registration = build(:event_registration, registered_at: nil)
        registration.valid?

        expect(registration.registered_at).to be_present
      end

      it 'does not override registered_at if already set' do
        specific_time = 2.days.ago
        registration = build(:event_registration, registered_at: specific_time)
        registration.valid?

        expect(registration.registered_at).to be_within(1.second).of(specific_time)
      end
    end
  end

  describe 'factory' do
    it 'creates valid registration' do
      registration = build(:event_registration)
      expect(registration).to be_valid
    end

    it 'creates confirmed registration with trait' do
      registration = create(:event_registration, :confirmed)
      expect(registration.status_confirmed?).to be true
    end

    it 'creates cancelled registration with trait' do
      registration = create(:event_registration, :cancelled)
      expect(registration.status_cancelled?).to be true
    end

    it 'creates registration with order using trait' do
      registration = create(:event_registration, :with_order)
      expect(registration.order).to be_present
    end
  end
end
