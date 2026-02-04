# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserMailer, type: :mailer do
  describe 'welcome_email' do
    let(:user) { create(:user, first_name: 'Иван', email: 'ivan@example.com') }
    let(:mail) { UserMailer.welcome_email(user) }

    it 'renders the subject' do
      expect(mail.subject).to eq('Добро пожаловать в Систему Бронникова!')
    end

    it 'renders the receiver email' do
      expect(mail.to).to eq([user.email])
    end

    it 'renders the sender email' do
      expect(mail.from).to eq(['noreply@bronnikov.com'])
    end

    it 'contains user first name' do
      expect(mail.body.encoded).to include(user.first_name)
    end

    it 'contains dashboard link' do
      expect(mail.body.encoded).to include('dashboard')
    end

    it 'contains welcome message' do
      expect(mail.body.encoded).to include('Добро пожаловать')
    end
  end

  describe 'order_confirmation' do
    let(:user) { create(:user, first_name: 'Иван') }
    let(:product) { create(:product, :published, name: 'Тестовый курс') }
    let(:order) { create(:order, user: user) }
    let!(:order_item) { create(:order_item, order: order, product: product) }
    let(:mail) { UserMailer.order_confirmation(order) }

    it 'renders the subject' do
      expect(mail.subject).to eq("Заказ ##{order.order_number} создан")
    end

    it 'renders the receiver email' do
      expect(mail.to).to eq([user.email])
    end

    it 'contains order number' do
      expect(mail.body.encoded).to include(order.order_number)
    end

    it 'contains product name' do
      expect(mail.body.encoded).to include(product.name)
    end

    it 'contains total amount' do
      expect(mail.body.encoded).to include(order.total.format)
    end

    it 'contains payment link' do
      expect(mail.body.encoded).to include('Перейти к оплате')
    end
  end

  describe 'payment_received' do
    let(:user) { create(:user) }
    let(:product) { create(:product, :published, name: 'Оплаченный курс') }
    let(:order) { create(:order, user: user, status: :paid) }
    let!(:order_item) { create(:order_item, order: order, product: product) }
    let(:mail) { UserMailer.payment_received(order) }

    it 'renders the subject' do
      expect(mail.subject).to eq("Оплата заказа ##{order.order_number} получена")
    end

    it 'renders the receiver email' do
      expect(mail.to).to eq([user.email])
    end

    it 'contains success message' do
      expect(mail.body.encoded).to include('Оплата получена')
    end

    it 'contains order number' do
      expect(mail.body.encoded).to include(order.order_number)
    end

    it 'contains product name' do
      expect(mail.body.encoded).to include(product.name)
    end

    it 'contains my courses link' do
      expect(mail.body.encoded).to include('my-courses')
    end
  end

  describe 'product_access_granted' do
    let(:user) { create(:user, first_name: 'Иван') }
    let(:product) { create(:product, :published, name: 'Новый курс') }
    let(:product_access) { create(:product_access, user: user, product: product) }
    let(:mail) { UserMailer.product_access_granted(product_access) }

    it 'renders the subject' do
      expect(mail.subject).to eq("Доступ к #{product.name} открыт!")
    end

    it 'renders the receiver email' do
      expect(mail.to).to eq([user.email])
    end

    it 'contains product name' do
      expect(mail.body.encoded).to include(product.name)
    end

    it 'contains access granted message' do
      expect(mail.body.encoded).to include('Доступ открыт')
    end

    it 'contains product link' do
      expect(mail.body.encoded).to include('/products/')
    end
  end

  describe 'password_reset' do
    let(:user) { create(:user, first_name: 'Иван') }
    let(:token) { 'test_token_123' }
    let(:mail) { UserMailer.password_reset(user, token) }

    it 'renders the subject' do
      expect(mail.subject).to eq('Восстановление пароля - Система Бронникова')
    end

    it 'renders the receiver email' do
      expect(mail.to).to eq([user.email])
    end

    it 'contains user first name' do
      expect(mail.body.encoded).to include(user.first_name)
    end

    it 'contains reset token in URL' do
      expect(mail.body.encoded).to include(token)
    end

    it 'contains reset password link' do
      expect(mail.body.encoded).to include('password_reset')
    end

    it 'contains expiration warning' do
      expect(mail.body.encoded).to include('24 часов')
    end
  end
end
