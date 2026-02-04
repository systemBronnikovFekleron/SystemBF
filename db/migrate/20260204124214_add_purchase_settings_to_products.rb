class AddPurchaseSettingsToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :auto_approve, :boolean, default: false, null: false
    add_column :products, :form_fields, :jsonb, default: {}

    add_index :products, :auto_approve
  end
end
