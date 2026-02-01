# frozen_string_literal: true

module Api
  module V1
    class UsersController < BaseController
      def show
        user = User.find(params[:id])
        authorize user

        render json: {
          id: user.id,
          email: user.email,
          first_name: user.first_name,
          last_name: user.last_name,
          classification: user.classification,
          active: user.active,
          profile: {
            phone: user.profile.phone,
            birth_date: user.profile.birth_date,
            city: user.profile.city,
            country: user.profile.country
          },
          wallet: {
            balance: user.wallet.balance.format
          },
          rating: {
            points: user.rating.points,
            level: user.rating.level
          }
        }
      end

      def update
        user = User.find(params[:id])
        authorize user

        if user.update(user_params)
          render json: { message: 'User updated successfully' }, status: :ok
        else
          render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def user_params
        params.require(:user).permit(:first_name, :last_name, :email, :password, :password_confirmation)
      end
    end
  end
end
