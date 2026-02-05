# frozen_string_literal: true

class ImpersonationPolicy < ApplicationPolicy
  def index?
    user&.admin_role?
  end

  def show?
    user&.admin_role?
  end

  def create?
    return false unless user&.admin_role?

    # Нельзя войти за самого себя
    return false if record.id == user.id

    # Нельзя войти за другого админа
    return false if record.admin_role?

    true
  end

  def destroy?
    user&.admin_role?
  end
end
