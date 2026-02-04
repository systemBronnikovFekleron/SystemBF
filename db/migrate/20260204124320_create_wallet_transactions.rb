class CreateWalletTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :wallet_transactions do |t|
      t.references :wallet, null: false, foreign_key: true, index: true
      t.references :order_request, null: true, foreign_key: true

      t.string :transaction_type, null: false
      t.integer :amount_kopecks, null: false
      t.integer :balance_before_kopecks, null: false
      t.integer :balance_after_kopecks, null: false

      t.text :description
      t.string :external_id

      t.timestamps
    end

    add_index :wallet_transactions, [:wallet_id, :created_at]
    add_index :wallet_transactions, :transaction_type
    add_index :wallet_transactions, :external_id
  end
end
