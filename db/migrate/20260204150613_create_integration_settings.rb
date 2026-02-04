# frozen_string_literal: true

class CreateIntegrationSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :integration_settings do |t|
      t.string :integration_type, null: false
      t.string :name, null: false
      t.text :description
      t.boolean :enabled, default: false, null: false
      t.text :encrypted_credentials
      t.jsonb :settings, default: {}, null: false
      t.integer :usage_count, default: 0, null: false
      t.datetime :last_used_at
      t.datetime :last_test_at
      t.string :last_test_status
      t.text :last_test_message
      t.bigint :created_by_id
      t.bigint :updated_by_id

      t.timestamps
    end

    add_index :integration_settings, :integration_type, unique: true
    add_index :integration_settings, :enabled
  end
end
