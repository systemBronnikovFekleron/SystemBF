# frozen_string_literal: true

module Admin
  class UserSubRolesController < BaseController
    before_action :set_user

    def index
      @active_roles = @user.user_sub_roles.active.includes(:sub_role, :granted_by).ordered
      @available_roles = SubRole.ordered
    end

    def create
      role = SubRole.find(params[:sub_role_id])
      @user.grant_sub_role!(role, granted_by: current_user, granted_via: 'manual')
      redirect_to admin_user_sub_roles_path(@user), notice: "Роль «#{role.display_name}» успешно назначена"
    rescue StandardError => e
      redirect_to admin_user_sub_roles_path(@user), alert: "Ошибка: #{e.message}"
    end

    def destroy
      user_sub_role = @user.user_sub_roles.find(params[:id])
      role_name = user_sub_role.sub_role.display_name
      user_sub_role.destroy
      redirect_to admin_user_sub_roles_path(@user), notice: "Роль «#{role_name}» успешно отозвана"
    end

    private

    def set_user
      @user = User.find(params[:user_id])
    end
  end
end
