# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Order, type: :model do
  subject { build(:order) }

  describe 'associations' do
    it { should belong_to(:user) }
    it { should have_many(:order_items).dependent(:destroy) }
    it { should have_many(:products).through(:order_items) }
  end

  describe 'callbacks' do
    it 'generates order number on create' do
      order = create(:order)
      expect(order.order_number).to match(/^ORD-\d+-[A-F0-9]{8}$/)
    end
  end

  describe 'AASM states' do
    let(:user) { create(:user) }
    let(:product) { create(:product, :published, price_kopecks: 50000) }
    let(:order) { create(:order, user: user, total_kopecks: 50000) }

    before do
      order.order_items.create!(product: product, price_kopecks: 50000, quantity: 1)
    end

    it 'starts in pending state' do
      expect(order.status).to eq('pending')
    end

    it 'can be processed' do
      order.process!
      expect(order.status).to eq('processing')
    end

    it 'grants product access when paid' do
      expect {
        order.pay!
      }.to change { ProductAccess.count }.by(1)

      expect(order.status).to eq('paid')
      expect(user.product_accesses.where(product: product).exists?).to be true
    end

    it 'can be completed from paid' do
      order.pay!
      order.complete!
      expect(order.status).to eq('completed')
    end

    it 'can fail from pending' do
      order.fail!
      expect(order.status).to eq('failed')
    end

    it 'revokes product access when refunded' do
      order.pay!
      expect(user.product_accesses.where(product: product).exists?).to be true

      order.refund!
      expect(order.status).to eq('refunded')
      expect(user.product_accesses.where(product: product).exists?).to be false
    end
  end

  describe 'monetize' do
    let(:order) { create(:order, total_kopecks: 250000) }

    it 'converts kopecks to money' do
      expect(order.total.format).to eq('2.500,00 ₽')
    end
  end
end
