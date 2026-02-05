# frozen_string_literal: true

class AddSubRolesToInitiations < ActiveRecord::Migration[8.1]
  def change
    add_column :initiations, :auto_grant_sub_roles, :jsonb, default: []
  end
end
