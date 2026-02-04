class CreateInteractionHistories < ActiveRecord::Migration[8.1]
  def change
    create_table :interaction_histories do |t|
      t.references :user, null: false, foreign_key: true
      t.references :admin_user, null: false, foreign_key: { to_table: :users }
      t.integer :interaction_type
      t.string :subject
      t.text :description
      t.datetime :interaction_date
      t.datetime :follow_up_date
      t.integer :status

      t.timestamps
    end
  end
end
