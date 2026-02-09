# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Event, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:category).optional }
    it { is_expected.to belong_to(:organizer).class_name('User').optional }
    it { is_expected.to have_many(:event_registrations).dependent(:destroy) }
    it { is_expected.to have_many(:registered_users).through(:event_registrations).source(:user) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:starts_at) }
    it { is_expected.to validate_numericality_of(:price_kopecks).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:max_participants).only_integer.is_greater_than(0).allow_nil }
  end

  describe 'enums' do
    it { is_expected.to define_enum_for(:status).with_values(draft: 0, published: 1, cancelled: 2, completed: 3).with_prefix(true) }
  end

  describe 'scopes' do
    describe '.published' do
      it 'returns only published events' do
        published = create(:event, status: :published)
        draft = create(:event, status: :draft)

        expect(Event.published).to include(published)
        expect(Event.published).not_to include(draft)
      end
    end

    describe '.upcoming' do
      it 'returns events starting in the future' do
        upcoming = create(:event, starts_at: 1.day.from_now)
        past = create(:event, starts_at: 1.day.ago)

        expect(Event.upcoming).to include(upcoming)
        expect(Event.upcoming).not_to include(past)
      end
    end

    describe '.past' do
      it 'returns events that have already started' do
        past = create(:event, starts_at: 1.day.ago)
        upcoming = create(:event, starts_at: 1.day.from_now)

        expect(Event.past).to include(past)
        expect(Event.past).not_to include(upcoming)
      end
    end

    describe '.online' do
      it 'returns only online events' do
        online = create(:event, :online)
        offline = create(:event, is_online: false)

        expect(Event.online).to include(online)
        expect(Event.online).not_to include(offline)
      end
    end

    describe '.offline' do
      it 'returns only offline events' do
        offline = create(:event, is_online: false)
        online = create(:event, :online)

        expect(Event.offline).to include(offline)
        expect(Event.offline).not_to include(online)
      end
    end

    describe '.ordered' do
      it 'orders by starts_at ascending' do
        later = create(:event, starts_at: 2.days.from_now)
        earlier = create(:event, starts_at: 1.day.from_now)

        expect(Event.ordered.first).to eq(earlier)
        expect(Event.ordered.last).to eq(later)
      end
    end
  end

  describe '#price' do
    it 'returns Money object in RUB' do
      event = build(:event, price_kopecks: 100_000)

      expect(event.price).to be_a(Money)
      expect(event.price.cents).to eq(100_000)
      expect(event.price.currency.iso_code).to eq('RUB')
    end
  end

  describe '#free?' do
    it 'returns true when price is zero' do
      event = build(:event, :free)
      expect(event.free?).to be true
    end

    it 'returns false when price is greater than zero' do
      event = build(:event, price_kopecks: 1000)
      expect(event.free?).to be false
    end
  end

  describe '#paid?' do
    it 'returns true when price is greater than zero' do
      event = build(:event, price_kopecks: 1000)
      expect(event.paid?).to be true
    end

    it 'returns false when price is zero' do
      event = build(:event, :free)
      expect(event.paid?).to be false
    end
  end

  describe '#full?' do
    context 'when max_participants is nil' do
      it 'returns false' do
        event = create(:event, :unlimited_seats)
        expect(event.full?).to be false
      end
    end

    context 'when max_participants is set' do
      it 'returns true when confirmed registrations reach max' do
        event = create(:event, max_participants: 2)
        create_list(:event_registration, 2, event: event, status: :confirmed)

        expect(event.full?).to be true
      end

      it 'returns false when confirmed registrations are less than max' do
        event = create(:event, max_participants: 5)
        create(:event_registration, event: event, status: :confirmed)

        expect(event.full?).to be false
      end

      it 'does not count pending registrations' do
        event = create(:event, max_participants: 2)
        create(:event_registration, event: event, status: :confirmed)
        create(:event_registration, event: event, status: :pending)

        expect(event.full?).to be false
      end
    end
  end

  describe '#confirmed_registrations_count' do
    it 'returns count of confirmed registrations only' do
      event = create(:event)
      create(:event_registration, event: event, status: :confirmed)
      create(:event_registration, event: event, status: :confirmed)
      create(:event_registration, event: event, status: :pending)
      create(:event_registration, event: event, status: :cancelled)

      expect(event.confirmed_registrations_count).to eq(2)
    end
  end

  describe '#available_spots' do
    context 'when max_participants is nil' do
      it 'returns nil' do
        event = create(:event, :unlimited_seats)
        expect(event.available_spots).to be_nil
      end
    end

    context 'when max_participants is set' do
      it 'returns remaining spots' do
        event = create(:event, max_participants: 10)
        create_list(:event_registration, 3, event: event, status: :confirmed)

        expect(event.available_spots).to eq(7)
      end
    end
  end

  describe '#past?' do
    it 'returns true for events that have started' do
      event = build(:event, starts_at: 1.hour.ago)
      expect(event.past?).to be true
    end

    it 'returns false for future events' do
      event = build(:event, starts_at: 1.hour.from_now)
      expect(event.past?).to be false
    end
  end

  describe '#upcoming?' do
    it 'returns true for future events' do
      event = build(:event, starts_at: 1.hour.from_now)
      expect(event.upcoming?).to be true
    end

    it 'returns false for events that have started' do
      event = build(:event, starts_at: 1.hour.ago)
      expect(event.upcoming?).to be false
    end
  end

  describe '#format_location' do
    it 'returns "Онлайн" for online events' do
      event = build(:event, :online)
      expect(event.format_location).to eq('Онлайн')
    end

    it 'returns location for offline events' do
      event = build(:event, location: 'Москва')
      expect(event.format_location).to eq('Москва')
    end
  end

  describe 'FriendlyId' do
    it 'generates slug from title' do
      event = create(:event, title: 'Тестовое событие')
      expect(event.slug).to be_present
    end
  end
end
