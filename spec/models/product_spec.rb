# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Product, type: :model do
  subject { build(:product) }

  describe 'associations' do
    it { should belong_to(:category).optional }
    it { should have_many(:order_items).dependent(:restrict_with_error) }
    it { should have_many(:product_accesses).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:product_type) }
    it { should validate_numericality_of(:price_kopecks).is_greater_than(0) }
  end

  describe 'product_type' do
    it 'has valid product types' do
      product = build(:product, product_type: :video)
      expect(product.product_type).to eq('video')

      product.product_type = :course
      expect(product.product_type).to eq('course')
    end
  end

  describe 'AASM states' do
    let(:product) { create(:product) }

    it 'starts in draft state' do
      expect(product.status).to eq('draft')
    end

    it 'can be published' do
      product.publish!
      expect(product.status).to eq('published')
    end

    it 'can be archived from draft' do
      product.archive!
      expect(product.status).to eq('archived')
    end

    it 'can be archived from published' do
      product.publish!
      product.archive!
      expect(product.status).to eq('archived')
    end

    it 'can be unarchived' do
      product.archive!
      product.unarchive!
      expect(product.status).to eq('draft')
    end
  end

  describe 'scopes' do
    before do
      create(:product, :published)
      create(:product, :archived)
      create(:product) # draft
    end

    it 'returns only published products' do
      expect(Product.published.count).to eq(1)
    end

    it 'returns only featured products' do
      create(:product, :featured, :published)
      expect(Product.featured.count).to eq(1)
    end
  end

  describe 'monetize' do
    let(:product) { create(:product, price_kopecks: 150000) }

    it 'converts kopecks to money' do
      expect(product.price.format).to eq('1.500,00 ₽')
    end
  end

  describe 'friendly_id' do
    it 'generates slug from name' do
      product = create(:product, name: 'Basic Course')
      expect(product.slug).to eq('basic-course')
    end
  end

  describe 'SubRoleRestrictable' do
    let(:product) { create(:product, :published) }
    let(:user) { create(:user) }
    let(:client_role) { SubRole.find_or_create_by!(name: 'client', display_name: 'Клиент', level: 1, system_role: true) }

    describe '.accessible_by' do
      it 'includes public products' do
        expect(Product.accessible_by(user)).to include(product)
      end

      it 'includes private products with required role' do
        product.add_required_roles([client_role.id])
        user.grant_sub_role!(client_role.id)
        expect(Product.accessible_by(user)).to include(product)
      end

      it 'excludes private products without required role' do
        product.add_required_roles([client_role.id])
        expect(Product.accessible_by(user)).not_to include(product)
      end

      it 'returns all public products for nil user' do
        public_product = create(:product, :published)
        private_product = create(:product, :published)
        private_product.add_required_roles([client_role.id])

        expect(Product.accessible_by(nil)).to include(public_product)
        expect(Product.accessible_by(nil)).not_to include(private_product)
      end
    end

    describe '#accessible_by?' do
      it 'returns true for public content' do
        expect(product.accessible_by?(user)).to be true
      end

      it 'returns true for private content with required role' do
        product.add_required_roles([client_role.id])
        user.grant_sub_role!(client_role.id)
        expect(product.accessible_by?(user)).to be true
      end

      it 'returns false for private content without required role' do
        product.add_required_roles([client_role.id])
        expect(product.accessible_by?(user)).to be false
      end

      it 'returns false for private content with nil user' do
        product.add_required_roles([client_role.id])
        expect(product.accessible_by?(nil)).to be false
      end
    end

    describe '#is_public?' do
      it 'returns true when no roles required' do
        expect(product.is_public?).to be true
      end

      it 'returns false when roles required' do
        product.add_required_roles([client_role.id])
        expect(product.is_public?).to be false
      end
    end

    describe '#is_private?' do
      it 'returns false when no roles required' do
        expect(product.is_private?).to be false
      end

      it 'returns true when roles required' do
        product.add_required_roles([client_role.id])
        expect(product.is_private?).to be true
      end
    end

    describe '#add_required_roles' do
      it 'adds roles by ids' do
        expect { product.add_required_roles([client_role.id]) }.to change { product.required_sub_roles.count }.by(1)
      end

      it 'adds roles by names' do
        expect { product.add_required_roles(['client']) }.to change { product.required_sub_roles.count }.by(1)
      end

      it 'does not duplicate roles' do
        product.add_required_roles([client_role.id])
        expect { product.add_required_roles([client_role.id]) }.not_to change { product.required_sub_roles.count }
      end
    end
  end
end
