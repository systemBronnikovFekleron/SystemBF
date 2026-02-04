# frozen_string_literal: true

module Admin
  class BaseController < ApplicationController
    layout 'admin'
    before_action :authenticate_user!
    before_action :authorize_admin!

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
  end
end
