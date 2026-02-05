# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'OrderRequest SubRole Assignment', type: :integration do
  let(:user) { create(:user) }
  let(:product) { create(:product, :published, price_kopecks: 100000, auto_approve: true) }
  let(:client_role) { SubRole.find_or_create_by!(name: 'client', display_name: 'Клиент', level: 1, system_role: true) }

  before do
    # Пополнить кошелек пользователя
    user.wallet.deposit_with_transaction(200000)
  end

  describe 'auto-grant on product purchase' do
    it 'grants configured sub_roles after successful purchase' do
      product.update!(auto_grant_sub_roles: [client_role.id])

      order_request = OrderRequest.create!(user: user, product: product)
      order_request.approve!

      expect(user.reload.has_sub_role?('client')).to be true
    end

    it 'grants multiple roles' do
      instructor_role = SubRole.find_or_create_by!(name: 'instructor_1', display_name: 'Инструктор 1', level: 5, system_role: true)
      product.update!(auto_grant_sub_roles: [client_role.id, instructor_role.id])

      order_request = OrderRequest.create!(user: user, product: product)
      order_request.approve!

      expect(user.reload.has_sub_role?('client')).to be true
      expect(user.reload.has_sub_role?('instructor_1')).to be true
    end

    it 'does not grant roles if product has no auto_grant configured' do
      order_request = OrderRequest.create!(user: user, product: product)
      order_request.approve!

      expect(user.reload.sub_roles.count).to eq(0)
    end

    it 'records source as product' do
      product.update!(auto_grant_sub_roles: [client_role.id])

      order_request = OrderRequest.create!(user: user, product: product)
      order_request.approve!

      user_sub_role = user.user_sub_roles.last
      expect(user_sub_role.source).to eq(product)
      expect(user_sub_role.granted_via).to eq('product_purchase')
    end
  end

  describe 'initiation completion' do
    let(:instructor) { create(:user, :instructor) }
    let(:initiation) do
      create(:initiation,
             user: user,
             conducted_by: instructor,
             status: :pending,
             auto_grant_sub_roles: [client_role.id])
    end

    it 'grants roles when initiation is completed' do
      initiation.update!(status: :completed)

      expect(user.reload.has_sub_role?('client')).to be true
    end

    it 'grants roles when initiation is passed' do
      initiation.update!(status: :passed)

      expect(user.reload.has_sub_role?('client')).to be true
    end

    it 'does not grant roles when initiation is failed' do
      initiation.update!(status: :failed)

      expect(user.reload.has_sub_role?('client')).to be false
    end

    it 'records source as initiation' do
      initiation.update!(status: :completed)

      user_sub_role = user.user_sub_roles.last
      expect(user_sub_role.source).to eq(initiation)
      expect(user_sub_role.granted_via).to eq('initiation_completed')
      expect(user_sub_role.granted_by).to eq(instructor)
    end
  end
end
