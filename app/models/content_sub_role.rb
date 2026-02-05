# frozen_string_literal: true

class ContentSubRole < ApplicationRecord
  belongs_to :sub_role
  belongs_to :content, polymorphic: true

  validates :sub_role_id, uniqueness: { scope: [:content_type, :content_id] }
end
