# frozen_string_literal: true

class HomeController < ApplicationController
  skip_before_action :verify_authenticity_token

  def index
    @featured_products = Product.published.featured.limit(3)
    @recent_products = Product.published.order(created_at: :desc).limit(6)
    @categories = Category.all
  end
end
