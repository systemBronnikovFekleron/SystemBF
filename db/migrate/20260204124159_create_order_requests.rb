class CreateOrderRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :order_requests do |t|
      t.references :user, null: false, foreign_key: true, index: true
      t.references :product, null: false, foreign_key: true, index: true
      t.references :order, null: true, foreign_key: true
      t.references :approved_by, foreign_key: { to_table: :users }

      t.string :request_number, null: false
      t.integer :total_kopecks, null: false
      t.string :status, null: false, default: 'pending'

      t.datetime :approved_at
      t.datetime :rejected_at
      t.text :rejection_reason
      t.datetime :paid_at
      t.string :payment_method

      t.jsonb :form_data, default: {}

      t.timestamps
    end

    add_index :order_requests, :request_number, unique: true
    add_index :order_requests, :status
    add_index :order_requests, [:user_id, :status]
    add_index :order_requests, [:product_id, :status]
    add_index :order_requests, :created_at
  end
end
