# frozen_string_literal: true

class UserSubRole < ApplicationRecord
  belongs_to :user
  belongs_to :sub_role
  belongs_to :granted_by, class_name: 'User', optional: true
  belongs_to :source, polymorphic: true, optional: true

  validates :user_id, uniqueness: { scope: :sub_role_id }
  validates :granted_at, presence: true

  before_validation :set_granted_at, on: :create

  scope :active, -> { where('expires_at IS NULL OR expires_at > ?', Time.current) }
  scope :expired, -> { where('expires_at IS NOT NULL AND expires_at <= ?', Time.current) }
  scope :ordered, -> { joins(:sub_role).order('sub_roles.level ASC') }

  def active?
    expires_at.nil? || expires_at > Time.current
  end

  private

  def set_granted_at
    self.granted_at ||= Time.current
  end
end
