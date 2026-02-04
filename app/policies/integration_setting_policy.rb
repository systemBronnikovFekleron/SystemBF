# frozen_string_literal: true

class IntegrationSettingPolicy < ApplicationPolicy
  # Все действия требуют admin роли
  def index?
    user&.classification_admin?
  end

  def show?
    user&.classification_admin?
  end

  def edit?
    user&.classification_admin?
  end

  def update?
    user&.classification_admin?
  end

  def test_connection?
    user&.classification_admin?
  end

  def toggle_status?
    user&.classification_admin?
  end

  def logs?
    user&.classification_admin?
  end

  def statistics?
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
