# frozen_string_literal: true

class AddSubRolesToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :auto_grant_sub_roles, :jsonb, default: []
  end
end
