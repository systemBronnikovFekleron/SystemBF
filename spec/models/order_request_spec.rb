# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OrderRequest, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:product) }
    it { should belong_to(:order).optional }
    it { should belong_to(:approved_by).optional }
    it { should have_many(:wallet_transactions).dependent(:nullify) }
  end

  describe 'validations' do
    subject { create(:order_request) }

    it { should validate_uniqueness_of(:request_number) }
    it { should validate_numericality_of(:total_kopecks).is_greater_than(0) }
    it { should validate_presence_of(:status) }

    context 'when rejected' do
      subject { build(:order_request, status: 'rejected', rejection_reason: 'Test') }
      it { should validate_presence_of(:rejection_reason) }
    end
  end

  describe 'callbacks' do
    describe 'before_create' do
      it 'generates request_number' do
        request = build(:order_request, request_number: nil)
        request.save
        expect(request.request_number).to match(/^REQ-\d+-[A-F0-9]{8}$/)
      end

      it 'sets total_kopecks from product' do
        product = create(:product, price_kopecks: 150_000)
        user = create(:user)
        request = OrderRequest.new(user: user, product: product)
        request.save
        expect(request.total_kopecks).to eq(150_000)
      end
    end
  end

  describe 'AASM states and events' do
    let(:user) { create(:user) }
    let(:product) { create(:product, price_kopecks: 100_000) }
    let(:request) { create(:order_request, user: user, product: product) }

    it 'has pending as initial state' do
      expect(request.status).to eq('pending')
    end

    describe '#approve!' do
      it 'transitions from pending to approved' do
        expect { request.approve! }.to change { request.status }.from('pending').to('approved')
      end

      it 'sets approved_at timestamp' do
        expect { request.approve! }.to change { request.approved_at }.from(nil)
      end

      context 'with auto_approve and sufficient balance' do
        before do
          product.update(auto_approve: true)
          user.wallet.update(balance_kopecks: 150_000)
        end

        it 'automatically pays the request' do
          request.approve!
          expect(request.status).to eq('paid')
        end

        it 'creates wallet transaction' do
          expect { request.approve! }.to change { user.wallet.wallet_transactions.count }.by(1)
        end
      end

      context 'with insufficient balance' do
        before do
          product.update(auto_approve: true)
          user.wallet.update(balance_kopecks: 50_000)
        end

        it 'does not pay the request' do
          request.approve!
          expect(request.status).to eq('approved')
        end
      end
    end

    describe '#reject!' do
      it 'transitions from pending to rejected' do
        request.update(rejection_reason: 'Test reason')
        expect { request.reject! }.to change { request.status }.from('pending').to('rejected')
      end

      it 'sets rejected_at timestamp' do
        request.update(rejection_reason: 'Test reason')
        expect { request.reject! }.to change { request.rejected_at }.from(nil)
      end
    end

    describe '#pay!' do
      let(:approved_request) { create(:order_request, :approved, user: user, product: product) }

      it 'transitions from approved to paid' do
        expect { approved_request.pay! }.to change { approved_request.status }.from('approved').to('paid')
      end

      it 'sets paid_at timestamp' do
        expect { approved_request.pay! }.to change { approved_request.paid_at }.from(nil)
      end

      it 'creates an order' do
        expect { approved_request.pay! }.to change { Order.count }.by(1)
      end

      it 'creates order items' do
        expect { approved_request.pay! }.to change { OrderItem.count }.by(1)
      end

      it 'grants product access' do
        expect { approved_request.pay! }.to change { ProductAccess.count }.by(1)
      end

      it 'completes the request' do
        approved_request.pay!
        expect(approved_request.reload.status).to eq('completed')
      end
    end

    describe '#complete!' do
      let(:paid_request) { create(:order_request, :paid, user: user, product: product) }

      it 'transitions from paid to completed' do
        expect { paid_request.complete! }.to change { paid_request.status }.from('paid').to('completed')
      end
    end

    describe '#cancel!' do
      it 'can cancel from pending' do
        expect { request.cancel! }.to change { request.status }.from('pending').to('cancelled')
      end

      it 'can cancel from approved' do
        approved = create(:order_request, :approved)
        expect { approved.cancel! }.to change { approved.status }.from('approved').to('cancelled')
      end
    end
  end

  describe 'scopes' do
    let!(:recent_request) { create(:order_request, created_at: 1.hour.ago) }
    let!(:old_request) { create(:order_request, created_at: 1.day.ago) }

    describe '.recent' do
      it 'returns requests ordered by created_at desc' do
        expect(OrderRequest.recent.first).to eq(recent_request)
      end
    end

    describe '.pending_approval' do
      let!(:pending) { create(:order_request, status: 'pending') }
      let!(:approved) { create(:order_request, :approved) }

      it 'returns only pending requests' do
        expect(OrderRequest.pending_approval).to include(pending)
        expect(OrderRequest.pending_approval).not_to include(approved)
      end
    end

    describe '.approved_pending_payment' do
      let!(:approved) { create(:order_request, :approved) }
      let!(:paid) { create(:order_request, :paid) }

      it 'returns only approved requests' do
        expect(OrderRequest.approved_pending_payment).to include(approved)
        expect(OrderRequest.approved_pending_payment).not_to include(paid)
      end
    end
  end

  describe '#total' do
    let(:request) { create(:order_request, total_kopecks: 150_000) }

    it 'returns Money object' do
      expect(request.total).to be_a(Money)
    end

    it 'returns correct amount' do
      expect(request.total.cents).to eq(150_000)
    end
  end
end
