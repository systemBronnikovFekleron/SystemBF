class CreateEventRegistrations < ActiveRecord::Migration[8.1]
  def change
    create_table :event_registrations do |t|
      t.references :user, null: false, foreign_key: true
      t.references :event, null: false, foreign_key: true
      t.references :order, foreign_key: true
      t.integer :status, default: 0
      t.datetime :registered_at, null: false
      t.text :notes
      t.timestamps
    end

    add_index :event_registrations, [:user_id, :event_id], unique: true
    add_index :event_registrations, :status
  end
end
