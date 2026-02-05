class CreateInitiations < ActiveRecord::Migration[8.1]
  def change
    create_table :initiations do |t|
      t.references :user, null: false, foreign_key: true
      t.string :initiation_type
      t.integer :level
      t.references :conducted_by, foreign_key: { to_table: :users }
      t.datetime :conducted_at
      t.integer :status, default: 0
      t.text :notes
      t.jsonb :results
      t.timestamps
    end

    add_index :initiations, :initiation_type
    add_index :initiations, :status
  end
end
