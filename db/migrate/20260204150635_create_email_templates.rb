# frozen_string_literal: true

class CreateEmailTemplates < ActiveRecord::Migration[8.1]
  def change
    create_table :email_templates do |t|
      t.string :template_key, null: false
      t.string :name, null: false
      t.string :category
      t.string :subject, null: false
      t.text :body_html, null: false
      t.text :body_text
      t.jsonb :available_variables, default: [], null: false
      t.boolean :active, default: true, null: false
      t.boolean :system_default, default: false, null: false
      t.integer :sent_count, default: 0, null: false
      t.datetime :last_sent_at
      t.bigint :updated_by_id

      t.timestamps
    end

    add_index :email_templates, :template_key, unique: true
    add_index :email_templates, :category
    add_index :email_templates, :active
  end
end
