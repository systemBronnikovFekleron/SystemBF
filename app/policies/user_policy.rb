# frozen_string_literal: true

class UserPolicy < ApplicationPolicy
  def show?
    user == record || user.classification_admin?
  end

  def update?
    user == record || user.classification_admin?
  end

  def destroy?
    user.classification_admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.classification_admin?
        scope.all
      else
        scope.where(id: user.id)
      end
    end
  end
end
