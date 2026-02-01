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
  has_one :business_account, dependent: :nullify
  has_many :orders, dependent: :destroy
  has_many :product_accesses, dependent: :destroy

  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :password, length: { minimum: 8 }, if: -> { new_record? || password.present? }

  before_save :normalize_email
  after_create :create_associated_records

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
