# frozen_string_literal: true

class InteractionHistory < ApplicationRecord
  belongs_to :user
  belongs_to :admin_user, class_name: 'User'

  enum :interaction_type, {
    call: 0,
    meeting: 1,
    email: 2,
    chat: 3,
    note: 4
  }, prefix: true

  enum :status, {
    planned: 0,
    completed: 1,
    cancelled: 2
  }, prefix: true

  validates :user_id, :admin_user_id, :interaction_type, :subject, :interaction_date, presence: true

  scope :recent, -> { order(interaction_date: :desc) }
  scope :upcoming, -> { where('follow_up_date >= ?', Time.current).order(:follow_up_date) }
end
