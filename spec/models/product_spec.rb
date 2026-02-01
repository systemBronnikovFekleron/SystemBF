# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Product, type: :model do
  subject { build(:product) }

  describe 'associations' do
    it { should belong_to(:category).optional }
    it { should have_many(:order_items).dependent(:restrict_with_error) }
    it { should have_many(:product_accesses).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:product_type) }
    it { should validate_numericality_of(:price_kopecks).is_greater_than(0) }
  end

  describe 'product_type' do
    it 'has valid product types' do
      product = build(:product, product_type: :video)
      expect(product.product_type).to eq('video')

      product.product_type = :course
      expect(product.product_type).to eq('course')
    end
  end

  describe 'AASM states' do
    let(:product) { create(:product) }

    it 'starts in draft state' do
      expect(product.status).to eq('draft')
    end

    it 'can be published' do
      product.publish!
      expect(product.status).to eq('published')
    end

    it 'can be archived from draft' do
      product.archive!
      expect(product.status).to eq('archived')
    end

    it 'can be archived from published' do
      product.publish!
      product.archive!
      expect(product.status).to eq('archived')
    end

    it 'can be unarchived' do
      product.archive!
      product.unarchive!
      expect(product.status).to eq('draft')
    end
  end

  describe 'scopes' do
    before do
      create(:product, :published)
      create(:product, :archived)
      create(:product) # draft
    end

    it 'returns only published products' do
      expect(Product.published.count).to eq(1)
    end

    it 'returns only featured products' do
      create(:product, :featured, :published)
      expect(Product.featured.count).to eq(1)
    end
  end

  describe 'monetize' do
    let(:product) { create(:product, price_kopecks: 150000) }

    it 'converts kopecks to money' do
      expect(product.price.format).to eq('1.500,00 ₽')
    end
  end

  describe 'friendly_id' do
    it 'generates slug from name' do
      product = create(:product, name: 'Basic Course')
      expect(product.slug).to eq('basic-course')
    end
  end
end
