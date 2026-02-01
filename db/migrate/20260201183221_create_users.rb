class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :password_digest, null: false
      t.string :first_name
      t.string :last_name
      t.integer :classification, default: 0, null: false
      t.boolean :active, default: true, null: false
      t.datetime :last_login_at
      t.inet :last_login_ip

      t.timestamps
    end
    add_index :users, :email, unique: true
    add_index :users, :classification
  end
end
