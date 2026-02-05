# frozen_string_literal: true

class CreateNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :notifications do |t|
      t.references :user, null: false, foreign_key: true
      t.string :notification_type, null: false
      t.string :title, null: false
      t.text :message
      t.boolean :read, default: false, null: false
      t.string :action_url
      t.string :action_text
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :notifications, :notification_type
    add_index :notifications, :read
    add_index :notifications, :created_at
    add_index :notifications, [:user_id, :read]
  end
end
