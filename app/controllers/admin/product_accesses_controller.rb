# frozen_string_literal: true

module Admin
  class ProductAccessesController < Admin::BaseController
    before_action :set_product_access, only: [:show, :destroy, :extend]

    def index
      @product_accesses = ProductAccess.includes(:user, :product, :order).order(created_at: :desc)

      # Filters
      @product_accesses = @product_accesses.where(product_id: params[:product_id]) if params[:product_id].present?
      @product_accesses = @product_accesses.where(user_id: params[:user_id]) if params[:user_id].present?

      case params[:status]
      when 'active'
        @product_accesses = @product_accesses.active
      when 'expired'
        @product_accesses = @product_accesses.where('expires_at IS NOT NULL AND expires_at <= ?', Time.current)
      end

      @product_accesses = @product_accesses.page(params[:page]).per(25)

      # Stats
      @total_count = ProductAccess.count
      @active_count = ProductAccess.active.count
      @expired_count = ProductAccess.where('expires_at IS NOT NULL AND expires_at <= ?', Time.current).count
      @permanent_count = ProductAccess.where(expires_at: nil).count
    end

    def show
      @user = @product_access.user
      @product = @product_access.product
    end

    def destroy
      @product_access.destroy
      redirect_to admin_product_accesses_path, notice: 'Доступ отозван'
    end

    def extend
      days = params[:days].to_i
      days = 30 if days <= 0

      if @product_access.expires_at.present?
        new_expiry = [@product_access.expires_at, Time.current].max + days.days
      else
        new_expiry = Time.current + days.days
      end

      @product_access.update!(expires_at: new_expiry)
      redirect_to admin_product_access_path(@product_access), notice: "Доступ продлён до #{l(new_expiry, format: :short)}"
    end

    private

    def set_product_access
      @product_access = ProductAccess.find(params[:id])
    end
  end
end
