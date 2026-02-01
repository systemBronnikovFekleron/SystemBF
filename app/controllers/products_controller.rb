# frozen_string_literal: true

class ProductsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:index, :show]

  def index
    @products = Product.published.ordered
    @products = @products.where(category_id: params[:category_id]) if params[:category_id].present?
    @products = @products.where(product_type: params[:product_type]) if params[:product_type].present?
    @products = @products.featured if params[:featured] == 'true'

    @categories = Category.all

    respond_to do |format|
      format.html
      format.json { render json: @products.map { |p| product_json(p) } }
    end
  end

  def show
    @product = Product.friendly.find(params[:id])

    respond_to do |format|
      format.html
      format.json { render json: product_json(@product) }
    end
  end

  private

  def product_json(product)
    {
      id: product.id,
      name: product.name,
      slug: product.slug,
      description: product.description,
      price: product.price.format,
      price_kopecks: product.price_kopecks,
      product_type: product.product_type,
      status: product.status,
      featured: product.featured,
      category: product.category&.name
    }
  end
end
