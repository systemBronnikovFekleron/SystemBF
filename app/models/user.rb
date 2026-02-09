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

  # Notifications
  has_many :notifications, dependent: :destroy

  # SubRoles
  has_many :user_sub_roles, dependent: :destroy
  has_many :sub_roles, through: :user_sub_roles
  has_many :granted_sub_roles, class_name: 'UserSubRole', foreign_key: :granted_by_id, dependent: :nullify

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

  # Полное имя с email для select-ов в админке
  def full_name_with_email
    name = [first_name, last_name].compact.join(' ')
    name.present? ? "#{name} (#{email})" : email
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

  # SubRole methods
  def has_sub_role?(role_name_or_id)
    if role_name_or_id.is_a?(Integer)
      sub_role_ids.include?(role_name_or_id)
    else
      sub_roles.exists?(name: role_name_or_id)
    end
  end

  def has_any_sub_role?(role_names_or_ids)
    return false if role_names_or_ids.blank?

    if role_names_or_ids.first.is_a?(Integer)
      (sub_role_ids & role_names_or_ids).any?
    else
      sub_roles.where(name: role_names_or_ids).exists?
    end
  end

  def grant_sub_role!(role_name_or_id, granted_by: nil, granted_via: 'manual', source: nil)
    role = role_name_or_id.is_a?(Integer) ? SubRole.find(role_name_or_id) : SubRole.find_by!(name: role_name_or_id)

    user_sub_roles.create!(
      sub_role: role,
      granted_by: granted_by,
      granted_via: granted_via,
      source: source,
      granted_at: Time.current
    )
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.info "User #{id} already has sub_role #{role.name}"
  end

  def grant_sub_roles!(role_ids_or_names, granted_by: nil, granted_via: 'manual', source: nil)
    Array(role_ids_or_names).each do |role|
      grant_sub_role!(role, granted_by: granted_by, granted_via: granted_via, source: source)
    end
  end

  def active_sub_roles
    user_sub_roles.active.includes(:sub_role).map(&:sub_role)
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
