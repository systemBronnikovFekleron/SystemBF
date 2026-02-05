# frozen_string_literal: true

class CreateImpersonationLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :impersonation_logs do |t|
      t.references :admin, null: false, foreign_key: { to_table: :users }, index: true
      t.references :user, null: false, foreign_key: { to_table: :users }, index: true
      t.string :session_token, null: false
      t.datetime :started_at, null: false
      t.datetime :ended_at
      t.string :ip_address
      t.string :user_agent
      t.text :reason
      t.timestamps
    end

    add_index :impersonation_logs, :session_token, unique: true
    add_index :impersonation_logs, :started_at
    add_index :impersonation_logs, [:admin_id, :started_at]
  end
end
