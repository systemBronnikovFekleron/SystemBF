# frozen_string_literal: true

module Admin
  class WalletTransactionsController < Admin::BaseController
    def index
      @transactions = WalletTransaction.includes(wallet: :user, order_request: :product).recent

      # Filters
      @transactions = @transactions.where(transaction_type: params[:transaction_type]) if params[:transaction_type].present?

      if params[:user_id].present?
        wallet_ids = Wallet.where(user_id: params[:user_id]).pluck(:id)
        @transactions = @transactions.where(wallet_id: wallet_ids)
      end

      # Date filters
      @transactions = @transactions.where('created_at >= ?', params[:date_from]) if params[:date_from].present?
      @transactions = @transactions.where('created_at <= ?', params[:date_to].to_date.end_of_day) if params[:date_to].present?

      @transactions = @transactions.page(params[:page]).per(25)

      # Stats
      @total_count = WalletTransaction.count
      @deposits_sum = WalletTransaction.transaction_type_deposit.sum(:amount_kopecks)
      @withdrawals_sum = WalletTransaction.transaction_type_withdrawal.sum(:amount_kopecks).abs
      @refunds_sum = WalletTransaction.transaction_type_refund.sum(:amount_kopecks)
    end

    def show
      @transaction = WalletTransaction.includes(wallet: :user, order_request: :product).find(params[:id])
      @user = @transaction.wallet.user
    end
  end
end
