# frozen_string_literal: true

module Admin
  class CategoriesController < Admin::BaseController
    before_action :set_category, only: [:show, :edit, :update, :destroy]

    def index
      @categories = Category.ordered.includes(:products)
      @categories_count = @categories.count
      @products_count = Product.count
    end

    def show
      @products = @category.products.page(params[:page]).per(20)
    end

    def new
      @category = Category.new
    end

    def create
      @category = Category.new(category_params)

      if @category.save
        redirect_to admin_categories_path, notice: 'Категория успешно создана'
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @category.update(category_params)
        redirect_to admin_categories_path, notice: 'Категория успешно обновлена'
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @category.products.any?
        redirect_to admin_categories_path, alert: "Невозможно удалить категорию с продуктами (#{@category.products.count})"
      else
        @category.destroy
        redirect_to admin_categories_path, notice: 'Категория удалена'
      end
    end

    def reorder
      params[:categories].each_with_index do |id, index|
        Category.find(id).update(position: index + 1)
      end
      head :ok
    end

    private

    def set_category
      @category = Category.friendly.find(params[:id])
    end

    def category_params
      params.require(:category).permit(:name, :slug, :description, :position)
    end
  end
end
