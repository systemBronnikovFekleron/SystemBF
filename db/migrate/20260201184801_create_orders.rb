class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.references :user, null: false, foreign_key: true
      t.string :order_number, null: false
      t.integer :total_kopecks, null: false
      t.string :status, default: 'pending', null: false
      t.string :payment_method
      t.string :payment_id
      t.datetime :paid_at

      t.timestamps
    end
    add_index :orders, :order_number, unique: true
    add_index :orders, :status
    add_index :orders, :paid_at
  end
end
