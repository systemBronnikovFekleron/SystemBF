# frozen_string_literal: true

class Article < ApplicationRecord
  extend FriendlyId

  # FriendlyId
  friendly_id :title, use: :slugged

  # Associations
  belongs_to :author, class_name: 'User', optional: true
  has_many :favorites, as: :favoritable, dependent: :destroy

  # Enums
  enum :article_type, {
    news: 0,
    useful_material: 1,
    announcement: 2
  }, prefix: true

  enum :status, {
    draft: 0,
    published: 1,
    archived: 2
  }, prefix: true

  # Validations
  validates :title, presence: true
  validates :content, presence: true

  # Scopes
  scope :published, -> { where(status: :published) }
  scope :featured, -> { where(featured: true) }
  scope :ordered, -> { order(published_at: :desc, created_at: :desc) }
  scope :by_type, ->(type) { where(article_type: type) }

  # Callbacks
  before_save :set_published_at, if: :will_save_change_to_status?

  # Methods
  def type_label
    case article_type
    when 'news'
      'Новость'
    when 'useful_material'
      'Полезный материал'
    when 'announcement'
      'Объявление'
    else
      article_type.humanize
    end
  end

  private

  def set_published_at
    if status_published? && published_at.nil?
      self.published_at = Time.current
    elsif !status_published?
      self.published_at = nil
    end
  end
end
