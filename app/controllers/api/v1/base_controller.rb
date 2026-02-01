# frozen_string_literal: true

module Api
  module V1
    class BaseController < ApplicationController
      include Pundit::Authorization

      skip_before_action :verify_authenticity_token
      before_action :authenticate_request

      rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

      private

      def authenticate_request
        token = cookies.encrypted[:jwt_token] ||
                request.headers['Authorization']&.split(' ')&.last

        if token
          decoded = JsonWebToken.decode(token)
          @current_user = User.find_by(id: decoded[:user_id]) if decoded
        end

        render json: { error: 'Unauthorized' }, status: :unauthorized unless @current_user
      end

      def current_user
        @current_user
      end

      def user_not_authorized
        render json: { error: 'Forbidden' }, status: :forbidden
      end
    end
  end
end
