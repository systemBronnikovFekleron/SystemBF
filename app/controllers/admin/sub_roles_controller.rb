# frozen_string_literal: true

module Admin
  class SubRolesController < BaseController
    before_action :set_sub_role, only: [:show, :edit, :update, :destroy]

    def index
      @sub_roles = SubRole.ordered.page(params[:page]).per(20)
      @stats = {
        total_roles: SubRole.count,
        system_roles: SubRole.system_roles.count,
        custom_roles: SubRole.custom_roles.count
      }
    end

    def show
      @users_count = @sub_role.users_count
      @content_count = @sub_role.content_count
    end

    def new
      @sub_role = SubRole.new
    end

    def create
      @sub_role = SubRole.new(sub_role_params)
      if @sub_role.save
        redirect_to admin_sub_role_path(@sub_role), notice: 'Роль успешно создана'
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      if @sub_role.system_role?
        redirect_to admin_sub_roles_path, alert: 'Системные роли нельзя редактировать'
      end
    end

    def update
      if @sub_role.system_role?
        redirect_to admin_sub_roles_path, alert: 'Системные роли нельзя редактировать'
        return
      end

      if @sub_role.update(sub_role_params)
        redirect_to admin_sub_role_path(@sub_role), notice: 'Роль успешно обновлена'
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @sub_role.system_role?
        redirect_to admin_sub_roles_path, alert: 'Системные роли нельзя удалять'
      elsif @sub_role.users.any?
        redirect_to admin_sub_roles_path, alert: 'Роль назначена пользователям и не может быть удалена'
      else
        @sub_role.destroy
        redirect_to admin_sub_roles_path, notice: 'Роль успешно удалена'
      end
    end

    private

    def set_sub_role
      @sub_role = SubRole.find(params[:id])
    end

    def sub_role_params
      params.require(:sub_role).permit(:name, :display_name, :description, :level)
    end
  end
end
