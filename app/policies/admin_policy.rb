# frozen_string_literal: true

class AdminPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def access?
    user&.admin_role?
  end

  def manage_products?
    user&.admin_role?
  end

  def manage_users?
    user&.admin_role?
  end

  def view_interactions?
    user&.admin_role?
  end

  def create_interaction?
    user&.admin_role?
  end
end
