class CreateDiagnostics < ActiveRecord::Migration[8.1]
  def change
    create_table :diagnostics do |t|
      t.references :user, null: false, foreign_key: true
      t.string :diagnostic_type
      t.references :conducted_by, foreign_key: { to_table: :users }
      t.datetime :conducted_at
      t.integer :status, default: 0
      t.jsonb :results
      t.text :recommendations
      t.integer :score
      t.timestamps
    end

    add_index :diagnostics, :diagnostic_type
    add_index :diagnostics, :status
  end
end
