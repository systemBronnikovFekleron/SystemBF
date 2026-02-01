class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.references :category, foreign_key: true
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.integer :price_kopecks, null: false
      t.string :product_type, null: false
      t.string :status, default: 'draft', null: false
      t.boolean :featured, default: false
      t.integer :position, default: 0

      t.timestamps
    end
    add_index :products, :slug, unique: true
    add_index :products, :status
    add_index :products, :featured
    add_index :products, :product_type
  end
end
