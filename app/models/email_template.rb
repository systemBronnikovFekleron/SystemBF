# frozen_string_literal: true

class EmailTemplate < ApplicationRecord
  # Associations
  belongs_to :updated_by, class_name: 'User', optional: true

  # Validations
  validates :template_key, presence: true, uniqueness: true
  validates :name, presence: true
  validates :subject, presence: true
  validates :body_html, presence: true
  validates :category, inclusion: {
    in: %w[user order product system],
    allow_nil: true
  }

  # Scopes
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :by_category, ->(category) { where(category: category) }
  scope :system_defaults, -> { where(system_default: true) }
  scope :custom, -> { where(system_default: false) }
  scope :recently_sent, -> { where.not(last_sent_at: nil).order(last_sent_at: :desc) }

  # Callbacks
  before_destroy :prevent_system_deletion

  # Rendering methods
  def render_subject(variables = {})
    render_template(subject, variables)
  end

  def render_body_html(variables = {})
    render_template(body_html, variables)
  end

  def render_body_text(variables = {})
    return nil if body_text.blank?
    render_template(body_text, variables)
  end

  # Send test email
  def send_test_email(recipient_email, test_variables = {})
    default_variables = generate_test_variables
    variables = default_variables.merge(test_variables)

    ApplicationMailer.with(
      to: recipient_email,
      subject: render_subject(variables),
      body_html: render_body_html(variables),
      body_text: render_body_text(variables)
    ).generic_email.deliver_later

    { success: true, message: "Тестовое письмо отправлено на #{recipient_email}" }
  rescue StandardError => e
    { success: false, message: "Ошибка отправки: #{e.message}" }
  end

  # Increment sent count
  def increment_sent!
    increment!(:sent_count)
    touch(:last_sent_at)
  end

  # Duplicate template
  def duplicate!(new_key, new_name)
    EmailTemplate.create!(
      template_key: new_key,
      name: new_name,
      category: category,
      subject: subject,
      body_html: body_html,
      body_text: body_text,
      available_variables: available_variables,
      active: false,
      system_default: false
    )
  end

  private

  def render_template(template, variables)
    result = template.dup
    variables.each do |key, value|
      result.gsub!("{{#{key}}}", value.to_s)
    end
    result
  end

  def generate_test_variables
    variables = {}
    available_variables.each do |var|
      variables[var] = case var
                       when 'user_name' then 'Иван Иванов'
                       when 'user_email' then 'test@example.com'
                       when 'order_number' then 'ORD-123456'
                       when 'product_name' then 'Тестовый продукт'
                       when 'price' then '1000 ₽'
                       when 'date' then Time.current.strftime('%d.%m.%Y')
                       else "[#{var}]"
                       end
    end
    variables
  end

  def prevent_system_deletion
    if system_default?
      errors.add(:base, 'Нельзя удалить системный шаблон')
      throw :abort
    end
  end
end
