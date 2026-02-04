# frozen_string_literal: true

module Admin
  class ProductsController < BaseController
    before_action :set_product, only: [:show, :edit, :update, :destroy]

    def index
      @products = Product.includes(:category).order(created_at: :desc)

      # Поиск
      if params[:search].present?
        @products = @products.where('name ILIKE ?', "%#{params[:search]}%")
      end

      # Фильтр по категории
      if params[:category_id].present?
        @products = @products.where(category_id: params[:category_id])
      end

      # Фильтр по статусу
      if params[:status].present?
        @products = @products.where(status: params[:status])
      end

      # Фильтр по типу
      if params[:product_type].present?
        @products = @products.where(product_type: params[:product_type])
      end

      @products = @products.page(params[:page]).per(20)
      @categories = Category.ordered
    end

    def show
      # show view
    end

    def new
      @product = Product.new
      @categories = Category.ordered
    end

    def create
      @product = Product.new(product_params)

      if @product.save
        redirect_to admin_product_path(@product), notice: 'Продукт успешно создан'
      else
        @categories = Category.ordered
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @categories = Category.ordered
    end

    def update
      if @product.update(product_params)
        redirect_to admin_product_path(@product), notice: 'Продукт успешно обновлен'
      else
        @categories = Category.ordered
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @product.destroy
      redirect_to admin_products_path, notice: 'Продукт успешно удален'
    end

    def bulk_action
      product_ids = params[:product_ids] || []
      action_type = params[:action_type]

      if product_ids.empty?
        redirect_to admin_products_path, alert: 'Не выбраны продукты'
        return
      end

      products = Product.where(id: product_ids)
      count = products.count

      case action_type
      when 'publish'
        products.each { |product| product.publish! if product.may_publish? }
        redirect_to admin_products_path, notice: "#{count} продуктов опубликовано"
      when 'archive'
        products.each { |product| product.archive! if product.may_archive? }
        redirect_to admin_products_path, notice: "#{count} продуктов архивировано"
      when 'delete'
        products.destroy_all
        redirect_to admin_products_path, notice: "#{count} продуктов удалено"
      else
        redirect_to admin_products_path, alert: 'Неизвестное действие'
      end
    end

    private

    def set_product
      @product = Product.friendly.find(params[:id])
    end

    def product_params
      params.require(:product).permit(
        :name,
        :slug,
        :description,
        :category_id,
        :price_kopecks,
        :product_type,
        :status,
        :featured,
        :duration_minutes,
        :access_duration_days
      )
    end
  end
end
