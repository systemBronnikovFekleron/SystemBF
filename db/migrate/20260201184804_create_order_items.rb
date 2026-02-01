class CreateOrderItems < ActiveRecord::Migration[8.1]
  def change
    create_table :order_items do |t|
      t.references :order, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :price_kopecks, null: false
      t.integer :quantity, default: 1, null: false

      t.timestamps
    end
  end
end
