# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Category, type: :model do
  subject { build(:category) }

  describe 'associations' do
    it { should have_many(:products).dependent(:nullify) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name) }
  end

  describe 'scopes' do
    it 'returns categories ordered by position' do
      category1 = create(:category, position: 2)
      category2 = create(:category, position: 1)
      category3 = create(:category, position: 3)

      expect(Category.ordered).to eq([category2, category1, category3])
    end
  end

  describe 'friendly_id' do
    it 'generates slug from name' do
      category = create(:category, name: 'My Courses')
      expect(category.slug).to eq('my-courses')
    end
  end
end
