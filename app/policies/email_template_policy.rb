# frozen_string_literal: true

class EmailTemplatePolicy < ApplicationPolicy
  # Все действия требуют admin роли
  def index?
    user&.classification_admin?
  end

  def show?
    user&.classification_admin?
  end

  def new?
    user&.classification_admin?
  end

  def create?
    user&.classification_admin?
  end

  def edit?
    user&.classification_admin?
  end

  def update?
    user&.classification_admin?
  end

  def destroy?
    # Нельзя удалять системные шаблоны
    user&.classification_admin? && !record.system_default?
  end

  def preview?
    user&.classification_admin?
  end

  def send_test?
    user&.classification_admin?
  end

  def duplicate?
    user&.classification_admin?
  end

  class Scope < Scope
    def resolve
      if user&.classification_admin?
        scope.all
      else
        scope.none
      end
    end
  end
end
