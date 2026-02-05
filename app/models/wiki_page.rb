# frozen_string_literal: true

class WikiPage < ApplicationRecord
  extend FriendlyId
  include SubRoleRestrictable

  # FriendlyId
  friendly_id :title, use: :slugged

  # Associations
  belongs_to :parent, class_name: 'WikiPage', optional: true
  belongs_to :created_by, class_name: 'User', optional: true
  belongs_to :updated_by, class_name: 'User', optional: true
  has_many :children, class_name: 'WikiPage', foreign_key: :parent_id, dependent: :nullify
  has_many :favorites, as: :favoritable, dependent: :destroy

  # Enums
  enum :status, {
    draft: 0,
    published: 1
  }, prefix: true

  # Validations
  validates :title, presence: true
  validates :content, presence: true

  # Scopes
  scope :published, -> { where(status: :published) }
  scope :root_pages, -> { where(parent_id: nil) }
  scope :ordered, -> { order(position: :asc, title: :asc) }

  # Methods
  def breadcrumbs
    crumbs = []
    current = self
    while current
      crumbs.unshift(current)
      current = current.parent
    end
    crumbs
  end

  def depth
    breadcrumbs.size - 1
  end

  def has_children?
    children.any?
  end
end
