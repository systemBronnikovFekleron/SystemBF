# frozen_string_literal: true

class CreateContentSubRoles < ActiveRecord::Migration[8.1]
  def change
    create_table :content_sub_roles do |t|
      t.references :sub_role, null: false, foreign_key: true, index: true
      t.references :content, polymorphic: true, null: false, index: true
      t.timestamps
    end

    add_index :content_sub_roles, [:content_type, :content_id, :sub_role_id],
              unique: true, name: 'index_content_sub_roles_unique'
  end
end
