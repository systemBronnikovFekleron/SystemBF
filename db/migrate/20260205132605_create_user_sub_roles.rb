# frozen_string_literal: true

class CreateUserSubRoles < ActiveRecord::Migration[8.1]
  def change
    create_table :user_sub_roles do |t|
      t.references :user, null: false, foreign_key: true, index: true
      t.references :sub_role, null: false, foreign_key: true, index: true
      t.bigint :granted_by_id
      t.string :granted_via
      t.bigint :source_id
      t.string :source_type
      t.datetime :granted_at, null: false
      t.datetime :expires_at
      t.timestamps
    end

    add_index :user_sub_roles, [:user_id, :sub_role_id], unique: true, name: 'index_user_sub_roles_unique'
    add_index :user_sub_roles, :granted_by_id
    add_index :user_sub_roles, [:source_type, :source_id], name: 'index_user_sub_roles_on_source'
    add_index :user_sub_roles, :expires_at

    add_foreign_key :user_sub_roles, :users, column: :granted_by_id
  end
end
