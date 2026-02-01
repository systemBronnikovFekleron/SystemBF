class CreateRatings < ActiveRecord::Migration[8.1]
  def change
    create_table :ratings do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :points, default: 0, null: false
      t.integer :level, default: 1, null: false

      t.timestamps
    end

    add_index :ratings, :points
    add_index :ratings, :level
  end
end
