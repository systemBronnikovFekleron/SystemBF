class CreateProductAccesses < ActiveRecord::Migration[8.1]
  def change
    create_table :product_accesses do |t|
      t.references :user, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.references :order, null: false, foreign_key: true
      t.datetime :expires_at

      t.timestamps
    end
    add_index :product_accesses, [:user_id, :product_id], unique: true
  end
end
