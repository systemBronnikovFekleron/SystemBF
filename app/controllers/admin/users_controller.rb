# frozen_string_literal: true

module Admin
  class UsersController < BaseController
    before_action :set_user, only: [:show, :edit, :update]

    def index
      @users = User.includes(:wallet, :rating).order(created_at: :desc)

      # Поиск
      if params[:search].present?
        @users = @users.where('email ILIKE ? OR first_name ILIKE ? OR last_name ILIKE ?',
                              "%#{params[:search]}%", "%#{params[:search]}%", "%#{params[:search]}%")
      end

      # Фильтр по классификации
      if params[:classification].present?
        @users = @users.where(classification: params[:classification])
      end

      @users = @users.page(params[:page]).per(20)
    end

    def show
      @orders = @user.orders.order(created_at: :desc).limit(10)
      @product_accesses = @user.product_accesses.includes(:product).limit(10)
    end

    def edit
      # edit view
    end

    def update
      if @user.update(user_params)
        redirect_to admin_user_path(@user), notice: 'Пользователь успешно обновлен'
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      params.require(:user).permit(:email, :first_name, :last_name, :classification)
    end
  end
end
