# frozen_string_literal: true

module Admin
  class FormGeneratorController < ApplicationController
    before_action :authenticate_user!
    before_action :authorize_admin!

    def show
      @product = Product.friendly.find(params[:product_id])
      @action_url = external_forms_submit_url
      @form_html = @product.external_form_html(@action_url)
    end

    private

    def authorize_admin!
      unless current_user.admin_role?
        redirect_to root_path, alert: 'Доступ запрещен' and return
      end
    end
  end
end
