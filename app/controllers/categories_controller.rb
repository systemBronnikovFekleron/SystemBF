# frozen_string_literal: true

class CategoriesController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:index, :show]

  def index
    @categories = Category.ordered
    render json: @categories
  end

  def show
    @category = Category.friendly.find(params[:id])
    @products = @category.products.published.ordered

    render json: {
      category: @category,
      products: @products.map { |p| product_json(p) }
    }
  end

  private

  def product_json(product)
    {
      id: product.id,
      name: product.name,
      slug: product.slug,
      description: product.description,
      price: product.price.format,
      product_type: product.product_type,
      featured: product.featured
    }
  end
end
