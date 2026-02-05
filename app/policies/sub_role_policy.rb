# frozen_string_literal: true

class SubRolePolicy < ApplicationPolicy
  def index?
    user&.admin_role?
  end

  def show?
    user&.admin_role?
  end

  def create?
    user&.admin_role?
  end

  def update?
    user&.admin_role? && !record.system_role?
  end

  def destroy?
    user&.admin_role? && !record.system_role? && record.users.none?
  end

  def assign_sub_roles?(target_user)
    return false unless user
    return true if user.admin_role?
    return true if user.classification_center_director?
    return true if user.classification_specialist?
    false
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user&.admin_role?
        scope.all
      else
        scope.none
      end
    end
  end
end
