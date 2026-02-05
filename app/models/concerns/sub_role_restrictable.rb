# frozen_string_literal: true

module SubRoleRestrictable
  extend ActiveSupport::Concern

  included do
    has_many :content_sub_roles, as: :content, dependent: :destroy
    has_many :required_sub_roles, through: :content_sub_roles, source: :sub_role

    scope :accessible_by, ->(user) {
      return published if user.blank?

      # Публичный контент (без ролей) + приватный контент с нужными ролями
      no_roles_ids = left_joins(:content_sub_roles)
                       .where(content_sub_roles: { id: nil })
                       .pluck(:id)

      with_roles_ids = joins(:content_sub_roles)
                         .where(content_sub_roles: { sub_role_id: user.sub_role_ids })
                         .distinct
                         .pluck(:id)

      published.where(id: no_roles_ids + with_roles_ids)
    }

    scope :public_content, -> { left_joins(:content_sub_roles).where(content_sub_roles: { id: nil }) }
    scope :private_content, -> { joins(:content_sub_roles).distinct }
  end

  def accessible_by?(user)
    return true if is_public?
    return false if user.blank?
    user.has_any_sub_role?(required_sub_role_ids)
  end

  def is_public?
    content_sub_roles.none?
  end

  def is_private?
    content_sub_roles.any?
  end

  def add_required_roles(role_ids_or_names)
    roles = if role_ids_or_names.first.is_a?(Integer)
              SubRole.where(id: role_ids_or_names)
            else
              SubRole.where(name: role_ids_or_names)
            end

    roles.each { |role| content_sub_roles.find_or_create_by!(sub_role: role) }
  end

  def required_sub_role_names
    required_sub_roles.pluck(:name)
  end

  def required_sub_role_ids
    required_sub_roles.pluck(:id)
  end
end
