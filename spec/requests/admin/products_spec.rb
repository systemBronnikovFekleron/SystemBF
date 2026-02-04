# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin::Products', type: :request do
  let(:admin) { create(:user, :admin) }
  let(:regular_user) { create(:user, :client) }

  before { sign_in(admin) }

  describe 'GET /admin/products' do
    let!(:products) { create_list(:product, 3, :published) }

    it 'shows products list' do
      get admin_products_path
      expect(response).to have_http_status(:ok)
    end

    it 'displays all products' do
      get admin_products_path
      products.each do |product|
        expect(response.body).to include(product.name)
      end
    end

    context 'with search filter' do
      it 'filters products by name' do
        product = create(:product, name: 'Уникальное название')
        get admin_products_path, params: { search: 'Уникальное' }

        expect(response.body).to include('Уникальное название')
      end
    end

    context 'with status filter' do
      let!(:draft) { create(:product, :draft) }

      it 'filters by status' do
        get admin_products_path, params: { status: 'draft' }
        expect(response.body).to include(draft.name)
      end
    end
  end

  describe 'POST /admin/products/bulk_action' do
    let!(:products) { create_list(:product, 3, :draft) }
    let(:product_ids) { products.map(&:id) }

    context 'publish action' do
      it 'publishes selected products' do
        post bulk_action_admin_products_path, params: {
          product_ids: product_ids,
          action_type: 'publish'
        }

        expect(response).to redirect_to(admin_products_path)
        expect(flash[:notice]).to include('опубликовано')
        products.each { |p| expect(p.reload.status).to eq('published') }
      end
    end

    context 'archive action' do
      let!(:published_products) { create_list(:product, 2, :published) }

      it 'archives selected products' do
        post bulk_action_admin_products_path, params: {
          product_ids: published_products.map(&:id),
          action_type: 'archive'
        }

        expect(response).to redirect_to(admin_products_path)
        published_products.each { |p| expect(p.reload.status).to eq('archived') }
      end
    end

    context 'delete action' do
      it 'deletes selected products' do
        expect {
          post bulk_action_admin_products_path, params: {
            product_ids: product_ids,
            action_type: 'delete'
          }
        }.to change(Product, :count).by(-3)
      end
    end

    context 'with no products selected' do
      it 'shows alert' do
        post bulk_action_admin_products_path, params: {
          product_ids: [],
          action_type: 'publish'
        }

        expect(response).to redirect_to(admin_products_path)
        expect(flash[:alert]).to include('Не выбраны')
      end
    end
  end

  describe 'GET /admin/products/new' do
    it 'shows new product form' do
      get new_admin_product_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST /admin/products' do
    let(:category) { create(:category) }
    let(:valid_params) do
      {
        product: {
          name: 'Новый продукт',
          description: 'Описание',
          category_id: category.id,
          price_kopecks: 100_000,
          product_type: 'course',
          status: 'draft'
        }
      }
    end

    it 'creates product' do
      expect {
        post admin_products_path, params: valid_params
      }.to change(Product, :count).by(1)
    end

    it 'redirects to product page' do
      post admin_products_path, params: valid_params
      expect(response).to redirect_to(admin_product_path(Product.last))
    end
  end

  describe 'PATCH /admin/products/:id' do
    let(:product) { create(:product, :draft) }

    it 'updates product' do
      patch admin_product_path(product), params: {
        product: { name: 'Обновленное название' }
      }

      expect(response).to redirect_to(admin_product_path(product))
      expect(product.reload.name).to eq('Обновленное название')
    end
  end

  describe 'DELETE /admin/products/:id' do
    let!(:product) { create(:product) }

    it 'deletes product' do
      expect {
        delete admin_product_path(product)
      }.to change(Product, :count).by(-1)
    end
  end

  context 'when not admin' do
    before { sign_in(regular_user) }

    it 'denies access' do
      get admin_products_path
      expect(response).to have_http_status(:forbidden)
    end
  end
end
