# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WalletTransaction, type: :model do
  describe 'associations' do
    it { should belong_to(:wallet) }
    it { should belong_to(:order_request).optional }
  end

  describe 'enums' do
    it 'defines transaction_type enum with string values' do
      expect(WalletTransaction.transaction_types.keys).to contain_exactly('deposit', 'withdrawal', 'refund')
    end

    it 'uses prefix for enum methods' do
      wallet = create(:wallet)
      transaction = create(:wallet_transaction, :deposit, wallet: wallet)
      expect(transaction).to respond_to(:transaction_type_deposit?)
    end
  end

  describe 'validations' do
    it { should validate_presence_of(:transaction_type) }
    it { should validate_presence_of(:amount_kopecks) }

    it 'validates amount_kopecks is not zero' do
      wallet = create(:wallet)
      transaction = build(:wallet_transaction, wallet: wallet, amount_kopecks: 0)
      expect(transaction).not_to be_valid
      expect(transaction.errors[:amount_kopecks]).to be_present
    end

    it { should validate_presence_of(:balance_before_kopecks) }
    it { should validate_numericality_of(:balance_before_kopecks).is_greater_than_or_equal_to(0) }
    it { should validate_presence_of(:balance_after_kopecks) }
    it { should validate_numericality_of(:balance_after_kopecks).is_greater_than_or_equal_to(0) }
  end

  describe 'scopes' do
    let(:wallet) { create(:wallet) }
    let!(:recent_transaction) { create(:wallet_transaction, wallet: wallet, created_at: 1.hour.ago) }
    let!(:old_transaction) { create(:wallet_transaction, wallet: wallet, created_at: 1.day.ago) }

    describe '.recent' do
      it 'returns transactions ordered by created_at desc' do
        expect(WalletTransaction.recent.first).to eq(recent_transaction)
      end
    end

    describe '.for_wallet' do
      let(:other_wallet) { create(:wallet) }
      let!(:other_transaction) { create(:wallet_transaction, wallet: other_wallet) }

      it 'returns only transactions for specified wallet' do
        expect(WalletTransaction.for_wallet(wallet.id)).to include(recent_transaction, old_transaction)
        expect(WalletTransaction.for_wallet(wallet.id)).not_to include(other_transaction)
      end
    end
  end

  describe 'money methods' do
    let(:transaction) { create(:wallet_transaction, amount_kopecks: 100_000, balance_before_kopecks: 50_000, balance_after_kopecks: 150_000) }

    describe '#amount' do
      it 'returns Money object' do
        expect(transaction.amount).to be_a(Money)
      end

      it 'returns absolute value' do
        expect(transaction.amount.cents).to eq(100_000)
      end
    end

    describe '#balance_before' do
      it 'returns Money object' do
        expect(transaction.balance_before).to be_a(Money)
      end

      it 'returns correct amount' do
        expect(transaction.balance_before.cents).to eq(50_000)
      end
    end

    describe '#balance_after' do
      it 'returns Money object' do
        expect(transaction.balance_after).to be_a(Money)
      end

      it 'returns correct amount' do
        expect(transaction.balance_after.cents).to eq(150_000)
      end
    end
  end

  describe 'transaction types' do
    let(:wallet) { create(:wallet) }

    it 'creates deposit transaction' do
      transaction = create(:wallet_transaction, :deposit, wallet: wallet)
      expect(transaction.transaction_type_deposit?).to be true
    end

    it 'creates withdrawal transaction' do
      transaction = create(:wallet_transaction, :withdrawal, wallet: wallet)
      expect(transaction.transaction_type_withdrawal?).to be true
    end

    it 'creates refund transaction' do
      transaction = create(:wallet_transaction, :refund, wallet: wallet)
      expect(transaction.transaction_type_refund?).to be true
    end
  end
end
