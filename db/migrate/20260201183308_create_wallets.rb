class CreateWallets < ActiveRecord::Migration[8.1]
  def change
    create_table :wallets do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :balance_kopecks, default: 0, null: false

      t.timestamps
    end

    add_index :wallets, :balance_kopecks
  end
end
