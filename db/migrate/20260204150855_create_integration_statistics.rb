# frozen_string_literal: true

class CreateIntegrationStatistics < ActiveRecord::Migration[8.1]
  def change
    create_table :integration_statistics do |t|
      t.bigint :integration_setting_id, null: false
      t.date :date, null: false
      t.string :period_type, null: false
      t.integer :total_requests, default: 0, null: false
      t.integer :successful_requests, default: 0, null: false
      t.integer :failed_requests, default: 0, null: false
      t.decimal :success_rate, precision: 5, scale: 2
      t.integer :avg_duration_ms

      t.timestamps
    end

    add_index :integration_statistics, [:integration_setting_id, :date, :period_type],
              unique: true, name: 'index_integration_stats_on_setting_date_period'
    add_index :integration_statistics, :date
  end
end
