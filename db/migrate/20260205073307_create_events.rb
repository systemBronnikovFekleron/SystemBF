class CreateEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :events do |t|
      t.string :title, null: false
      t.string :slug, null: false
      t.text :description
      t.datetime :starts_at, null: false
      t.datetime :ends_at
      t.string :location
      t.boolean :is_online, default: false
      t.integer :max_participants
      t.integer :price_kopecks, default: 0
      t.references :category, foreign_key: true
      t.references :organizer, foreign_key: { to_table: :users }
      t.integer :status, default: 0
      t.boolean :auto_approve, default: true
      t.timestamps
    end

    add_index :events, :slug, unique: true
    add_index :events, :starts_at
    add_index :events, :status
  end
end
