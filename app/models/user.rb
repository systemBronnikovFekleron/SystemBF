# frozen_string_literal: true

class User < ApplicationRecord
  has_secure_password

  # 11 типов классификации пользователей
  enum :classification, {
    guest: 0,           # Гости
    client: 1,          # Клиенты
    club_member: 2,     # Участники клуба
    representative: 3,  # Представители
    trainee: 4,         # Стажеры
    instructor_1: 5,    # Инструктор 1 кат
    instructor_2: 6,    # Инструктор 2 кат
    instructor_3: 7,    # Инструктор 3 кат
    specialist: 8,      # Специалисты
    expert: 9,          # Эксперт-Диагност
    center_director: 10, # Директор Центра
    curator: 11,        # Куратор
    manager: 12,        # Менеджер платформы
    admin: 13           # Администратор
  }, prefix: true

  has_one :profile, dependent: :destroy
  has_one :wallet, dependent: :destroy
  has_one :rating, dependent: :destroy
  # has_one :business_account, dependent: :nullify # TODO: Phase 2 - Бизнес-аккаунт
  has_many :orders, dependent: :destroy
  has_many :product_accesses, dependent: :destroy
  has_many :order_requests, dependent: :destroy
  has_many :approved_requests, class_name: 'OrderRequest', foreign_key: :approved_by_id, dependent: :nullify, inverse_of: :approved_by

  # New associations for development map
  has_many :initiations, dependent: :destroy
  has_many :diagnostics, dependent: :destroy
  has_many :conducted_initiations, class_name: 'Initiation', foreign_key: :conducted_by_id, dependent: :nullify
  has_many :conducted_diagnostics, class_name: 'Diagnostic', foreign_key: :conducted_by_id, dependent: :nullify

  # Events
  has_many :event_registrations, dependent: :destroy
  has_many :registered_events, through: :event_registrations, source: :event
  has_many :organized_events, class_name: 'Event', foreign_key: :organizer_id, dependent: :nullify

  # Content
  has_many :authored_articles, class_name: 'Article', foreign_key: :author_id, dependent: :nullify
  has_many :created_wiki_pages, class_name: 'WikiPage', foreign_key: :created_by_id, dependent: :nullify
  has_many :updated_wiki_pages, class_name: 'WikiPage', foreign_key: :updated_by_id, dependent: :nullify

  # Favorites
  has_many :favorites, dependent: :destroy

  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :password, length: { minimum: 8 }, if: -> { new_record? || password.present? }

  before_save :normalize_email
  after_create :create_associated_records

  # Проверка прав администратора (admin, manager, curator)
  def admin_role?
    classification_admin? || classification_manager? || classification_curator?
  end

  # Проверка возможности одобрять заявки
  def can_approve_requests?
    admin_role? || classification_center_director? || classification_specialist?
  end

  # Полное имя пользователя
  def full_name
    [first_name, last_name].compact.join(' ').presence || email
  end

  # Password reset methods
  def create_reset_password_token!
    self.reset_password_token = SecureRandom.urlsafe_base64(32)
    self.reset_password_sent_at = Time.current
    save!(validate: false)
  end

  def reset_password_token_expired?
    reset_password_sent_at.nil? || reset_password_sent_at < 24.hours.ago
  end

  def clear_reset_password_token!
    self.reset_password_token = nil
    self.reset_password_sent_at = nil
    save!(validate: false)
  end

  private

  def normalize_email
    self.email = email.downcase.strip if email.present?
  end

  def create_associated_records
    create_profile
    create_wallet
    create_rating
  end
end
