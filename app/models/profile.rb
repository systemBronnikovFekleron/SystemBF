# frozen_string_literal: true

class Profile < ApplicationRecord
  belongs_to :user

  validates :phone, format: { with: /\A\+?\d{10,15}\z/, message: "должен быть валидным номером телефона" }, allow_blank: true
end
