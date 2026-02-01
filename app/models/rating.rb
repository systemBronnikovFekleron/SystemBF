# frozen_string_literal: true

class Rating < ApplicationRecord
  belongs_to :user

  validates :points, numericality: { greater_than_or_equal_to: 0 }
  validates :level, numericality: { greater_than_or_equal_to: 1 }

  after_update :recalculate_level

  def add_points(amount)
    increment!(:points, amount)
  end

  private

  def recalculate_level
    # Логика расчета уровня на основе points
    # 100 очков = 1 уровень
    new_level = (points / 100) + 1
    update_column(:level, new_level) if new_level != level
  end
end
