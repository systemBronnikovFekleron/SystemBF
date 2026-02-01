class CreateProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :profiles do |t|
      t.references :user, null: false, foreign_key: true
      t.string :phone
      t.date :birth_date
      t.text :bio
      t.string :city
      t.string :country, default: 'RU'

      t.timestamps
    end
  end
end
