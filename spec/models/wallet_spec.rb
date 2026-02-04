# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Wallet, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should have_many(:wallet_transactions).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_numericality_of(:balance_kopecks).is_greater_than_or_equal_to(0) }
  end

  describe '#withdraw_with_transaction' do
    let(:user) { create(:user) }
    let(:wallet) { user.wallet }

    before do
      wallet.update(balance_kopecks: 100_000)
    end

    context 'with sufficient balance' do
      let(:amount) { 50_000 }

      it 'reduces balance' do
        expect { wallet.withdraw_with_transaction(amount) }
          .to change { wallet.reload.balance_kopecks }.from(100_000).to(50_000)
      end

      it 'creates wallet transaction' do
        expect { wallet.withdraw_with_transaction(amount) }
          .to change { wallet.wallet_transactions.count }.by(1)
      end

      it 'creates withdrawal transaction with correct amounts' do
        wallet.withdraw_with_transaction(amount)
        transaction = wallet.wallet_transactions.last

        expect(transaction.transaction_type_withdrawal?).to be true
        expect(transaction.amount_kopecks).to eq(-amount)
        expect(transaction.balance_before_kopecks).to eq(100_000)
        expect(transaction.balance_after_kopecks).to eq(50_000)
      end

      it 'links transaction to order_request if provided' do
        order_request = create(:order_request, user: user)
        wallet.withdraw_with_transaction(amount, order_request)

        transaction = wallet.wallet_transactions.last
        expect(transaction.order_request).to eq(order_request)
      end
    end

    context 'with insufficient balance' do
      let(:amount) { 150_000 }

      it 'raises error' do
        expect { wallet.withdraw_with_transaction(amount) }
          .to raise_error(ArgumentError, 'Insufficient balance')
      end

      it 'does not change balance' do
        expect { wallet.withdraw_with_transaction(amount) rescue nil }
          .not_to change { wallet.reload.balance_kopecks }
      end

      it 'does not create transaction' do
        expect { wallet.withdraw_with_transaction(amount) rescue nil }
          .not_to change { wallet.wallet_transactions.count }
      end
    end
  end

  describe '#deposit_with_transaction' do
    let(:user) { create(:user) }
    let(:wallet) { user.wallet }

    before do
      wallet.update(balance_kopecks: 50_000)
    end

    context 'with valid amount' do
      let(:amount) { 100_000 }

      it 'increases balance' do
        expect { wallet.deposit_with_transaction(amount) }
          .to change { wallet.reload.balance_kopecks }.from(50_000).to(150_000)
      end

      it 'creates wallet transaction' do
        expect { wallet.deposit_with_transaction(amount) }
          .to change { wallet.wallet_transactions.count }.by(1)
      end

      it 'creates deposit transaction with correct amounts' do
        wallet.deposit_with_transaction(amount)
        transaction = wallet.wallet_transactions.last

        expect(transaction.transaction_type_deposit?).to be true
        expect(transaction.amount_kopecks).to eq(amount)
        expect(transaction.balance_before_kopecks).to eq(50_000)
        expect(transaction.balance_after_kopecks).to eq(150_000)
      end

      it 'saves external_id if provided' do
        wallet.deposit_with_transaction(amount, 'CP-12345')
        transaction = wallet.wallet_transactions.last
        expect(transaction.external_id).to eq('CP-12345')
      end

      it 'saves custom description if provided' do
        wallet.deposit_with_transaction(amount, nil, 'Custom deposit')
        transaction = wallet.wallet_transactions.last
        expect(transaction.description).to eq('Custom deposit')
      end
    end

    context 'with zero or negative amount' do
      it 'raises error' do
        expect { wallet.deposit_with_transaction(0) }
          .to raise_error(ArgumentError, 'Amount must be positive')

        expect { wallet.deposit_with_transaction(-100) }
          .to raise_error(ArgumentError, 'Amount must be positive')
      end
    end
  end

  describe '#refund_with_transaction' do
    let(:user) { create(:user) }
    let(:wallet) { user.wallet }
    let(:order_request) { create(:order_request, user: user) }

    before do
      wallet.update(balance_kopecks: 50_000)
    end

    context 'with valid amount' do
      let(:amount) { 100_000 }

      it 'increases balance' do
        expect { wallet.refund_with_transaction(amount, order_request) }
          .to change { wallet.reload.balance_kopecks }.from(50_000).to(150_000)
      end

      it 'creates refund transaction' do
        wallet.refund_with_transaction(amount, order_request)
        transaction = wallet.wallet_transactions.last

        expect(transaction.transaction_type_refund?).to be true
        expect(transaction.amount_kopecks).to eq(amount)
        expect(transaction.order_request).to eq(order_request)
      end
    end
  end

  describe '#sufficient_balance?' do
    let(:wallet) { create(:wallet, balance_kopecks: 100_000) }

    it 'returns true when balance is sufficient' do
      expect(wallet.sufficient_balance?(50_000)).to be true
      expect(wallet.sufficient_balance?(100_000)).to be true
    end

    it 'returns false when balance is insufficient' do
      expect(wallet.sufficient_balance?(150_000)).to be false
    end
  end

  describe 'race condition prevention' do
    let(:user) { create(:user) }
    let(:wallet) { user.wallet }

    before do
      wallet.update(balance_kopecks: 100_000)
    end

    it 'uses database locking in withdraw_with_transaction' do
      expect(wallet).to receive(:lock!).and_call_original
      wallet.withdraw_with_transaction(50_000)
    end

    it 'uses database locking in deposit_with_transaction' do
      expect(wallet).to receive(:lock!).and_call_original
      wallet.deposit_with_transaction(50_000)
    end
  end
end
