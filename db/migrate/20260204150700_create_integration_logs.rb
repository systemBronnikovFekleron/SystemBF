# frozen_string_literal: true

class CreateIntegrationLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :integration_logs do |t|
      t.bigint :integration_setting_id, null: false
      t.string :event_type, null: false
      t.string :status, null: false
      t.text :message
      t.jsonb :metadata, default: {}, null: false
      t.text :error_details
      t.string :related_type
      t.bigint :related_id
      t.integer :duration_ms

      t.datetime :created_at, null: false
    end

    add_index :integration_logs, [:integration_setting_id, :status, :created_at],
              name: 'index_integration_logs_on_setting_status_created'
    add_index :integration_logs, :event_type
    add_index :integration_logs, [:related_type, :related_id]
  end
end
