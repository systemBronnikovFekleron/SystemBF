# frozen_string_literal: true

# == Schema Information
#
# Table name: notifications
#
#  id                :bigint           not null, primary key
#  user_id           :bigint           not null
#  notification_type :string           not null
#  title             :string           not null
#  message           :text
#  read              :boolean          default(FALSE), not null
#  action_url        :string
#  action_text       :string
#  metadata          :jsonb
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
class Notification < ApplicationRecord
  belongs_to :user

  # Типы уведомлений (string enum для гибкости)
  NOTIFICATION_TYPES = {
    order_paid: 'order_paid',
    order_completed: 'order_completed',
    product_access_granted: 'product_access_granted',
    achievement_unlocked: 'achievement_unlocked',
    wallet_deposit: 'wallet_deposit',
    wallet_withdrawal: 'wallet_withdrawal',
    wallet_refund: 'wallet_refund',
    profile_updated: 'profile_updated',
    system: 'system',
    event_registration: 'event_registration',
    event_reminder: 'event_reminder',
    order_request_created: 'order_request_created',
    order_request_approved: 'order_request_approved',
    order_request_rejected: 'order_request_rejected',
    order_request_paid: 'order_request_paid',
    initiation_completed: 'initiation_completed',
    diagnostic_completed: 'diagnostic_completed'
  }.freeze

  # Validations
  validates :notification_type, presence: true, inclusion: { in: NOTIFICATION_TYPES.values }
  validates :title, presence: true
  validates :read, inclusion: { in: [true, false] }

  # Scopes
  scope :unread, -> { where(read: false) }
  scope :read_notifications, -> { where(read: true) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_type, ->(type) { where(notification_type: type) }

  # Methods
  def mark_as_read!
    update(read: true)
  end

  def mark_as_unread!
    update(read: false)
  end

  # Тип в читаемом виде
  def type_label
    I18n.t("notifications.types.#{notification_type}", default: notification_type.humanize)
  end

  # Иконка для типа уведомления
  def type_icon
    case notification_type
    when 'order_paid', 'order_completed'
      '💰'
    when 'product_access_granted'
      '🎓'
    when 'achievement_unlocked'
      '🏆'
    when 'wallet_deposit', 'wallet_refund'
      '💵'
    when 'wallet_withdrawal'
      '💸'
    when 'event_registration', 'event_reminder'
      '📅'
    when 'order_request_created', 'order_request_approved', 'order_request_paid'
      '📝'
    when 'order_request_rejected'
      '❌'
    when 'initiation_completed'
      '✨'
    when 'diagnostic_completed'
      '🔬'
    when 'system'
      '📢'
    else
      'ℹ️'
    end
  end
end
