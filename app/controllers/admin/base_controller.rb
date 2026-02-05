# frozen_string_literal: true

module Admin
  class BaseController < ApplicationController
    layout 'admin'
    before_action :authenticate_user!
    before_action :authorize_admin!
    before_action :block_admin_during_impersonation, unless: :impersonations_controller?

    private

    def authorize_admin!
      unless current_user&.admin_role?
        respond_to do |format|
          format.html do
            redirect_to root_path, alert: 'У вас нет прав доступа к административной панели'
          end
          format.json { render json: { error: 'Forbidden' }, status: :forbidden }
        end
      end
    end

    def impersonations_controller?
      controller_name == 'impersonations' && action_name == 'destroy'
    end
  end
end
