# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Notification, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:user) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:notification_type) }
    it { is_expected.to validate_presence_of(:title) }

    it 'validates notification_type inclusion' do
      expect(Notification::NOTIFICATION_TYPES.values).to all(be_a(String))

      # Valid type
      notification = build(:notification, notification_type: 'system')
      expect(notification).to be_valid

      # Invalid type
      notification = build(:notification, notification_type: 'invalid_type')
      expect(notification).not_to be_valid
    end
  end

  describe 'scopes' do
    let!(:user) { create(:user) }

    context 'read/unread' do
      let!(:unread_notification) { create(:notification, user: user, read: false) }
      let!(:read_notification) { create(:notification, user: user, read: true) }

      it 'returns unread notifications' do
        expect(Notification.unread).to include(unread_notification)
        expect(Notification.unread).not_to include(read_notification)
      end

      it 'returns read notifications' do
        expect(Notification.read_notifications).to include(read_notification)
        expect(Notification.read_notifications).not_to include(unread_notification)
      end
    end

    context 'ordering' do
      it 'returns notifications in recent order' do
        older = create(:notification, user: user, created_at: 2.days.ago)
        newer = create(:notification, user: user, created_at: 1.day.ago)

        recent_notifications = user.notifications.recent
        expect(recent_notifications.first).to eq(newer)
        expect(recent_notifications.last).to eq(older)
      end
    end

    context 'filtering by type' do
      it 'filters by type' do
        system_notification = create(:notification, user: user, notification_type: 'system')
        order_notification = create(:notification, user: user, notification_type: 'order_paid')

        expect(Notification.by_type('system')).to include(system_notification)
        expect(Notification.by_type('system')).not_to include(order_notification)
      end
    end
  end

  describe '#mark_as_read!' do
    it 'marks notification as read' do
      notification = create(:notification, read: false)
      expect { notification.mark_as_read! }.to change { notification.read }.from(false).to(true)
    end
  end

  describe '#mark_as_unread!' do
    it 'marks notification as unread' do
      notification = create(:notification, read: true)
      expect { notification.mark_as_unread! }.to change { notification.read }.from(true).to(false)
    end
  end

  describe '#type_icon' do
    it 'returns correct icons for different types' do
      expect(build(:notification, notification_type: 'order_paid').type_icon).to eq('💰')
      expect(build(:notification, notification_type: 'product_access_granted').type_icon).to eq('🎓')
      expect(build(:notification, notification_type: 'achievement_unlocked').type_icon).to eq('🏆')
      expect(build(:notification, notification_type: 'system').type_icon).to eq('📢')
    end
  end
end
