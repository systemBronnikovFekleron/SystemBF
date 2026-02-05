# frozen_string_literal: true

class SubRole < ApplicationRecord
  has_many :user_sub_roles, dependent: :destroy
  has_many :users, through: :user_sub_roles
  has_many :content_sub_roles, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :display_name, presence: true
  validates :level, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :ordered, -> { order(level: :asc, name: :asc) }
  scope :system_roles, -> { where(system_role: true) }
  scope :custom_roles, -> { where(system_role: false) }

  # Константы для всех 14 типов ролей
  GUEST = 'guest'
  CLIENT = 'client'
  CLUB_MEMBER = 'club_member'
  REPRESENTATIVE = 'representative'
  TRAINEE = 'trainee'
  INSTRUCTOR_1 = 'instructor_1'
  INSTRUCTOR_2 = 'instructor_2'
  INSTRUCTOR_3 = 'instructor_3'
  SPECIALIST = 'specialist'
  EXPERT = 'expert'
  CENTER_DIRECTOR = 'center_director'
  CURATOR = 'curator'
  MANAGER = 'manager'
  ADMIN = 'admin'

  def users_count
    Rails.cache.fetch("sub_role_#{id}_users_count", expires_in: 1.hour) { users.count }
  end

  def content_count
    Rails.cache.fetch("sub_role_#{id}_content_count", expires_in: 1.hour) { content_sub_roles.count }
  end
end
