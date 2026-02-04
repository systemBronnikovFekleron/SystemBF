# frozen_string_literal: true

class ExternalFormsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:submit]
  before_action :validate_required_fields, only: [:submit]

  def submit
    @product = Product.find(params[:product_id])

    unless @product.status_published?
      render json: { success: false, error: 'Продукт недоступен' }, status: :unprocessable_entity and return
    end

    @user = find_or_create_user
    @order_request = create_order_request

    if @order_request.persisted?
      handle_successful_submission
    else
      render json: {
        success: false,
        error: @order_request.errors.full_messages.join(', ')
      }, status: :unprocessable_entity
    end
  rescue StandardError => e
    Rails.logger.error "External form submission failed: #{e.message}"
    render json: { success: false, error: 'Внутренняя ошибка сервера' }, status: :internal_server_error
  end

  private

  def validate_required_fields
    unless params[:email].present? && params[:product_id].present?
      render json: { success: false, error: 'Email и Product ID обязательны' },
             status: :unprocessable_entity and return
    end
  end

  def find_or_create_user
    email = params[:email].to_s.downcase.strip
    user = User.find_by(email: email)

    return user if user.present?

    # Create new user
    password = SecureRandom.alphanumeric(12)
    user = User.create!(
      email: email,
      password: password,
      password_confirmation: password,
      first_name: params[:first_name].to_s.strip.presence,
      last_name: params[:last_name].to_s.strip.presence,
      classification: :client
    )

    # Send welcome email with password
    UserMailer.welcome_external_form(user, password).deliver_later

    user
  end

  def create_order_request
    @user.order_requests.create(
      product: @product,
      form_data: build_form_data
    )
  end

  def build_form_data
    data = {
      email: params[:email],
      first_name: params[:first_name],
      last_name: params[:last_name],
      phone: params[:phone]
    }

    # Add custom fields from product.form_fields
    @product.form_fields.each do |field|
      field_name = field['name']
      data[field_name] = params[field_name] if params[field_name].present?
    end

    data.compact
  end

  def handle_successful_submission
    # Auto-approve if enabled
    if @product.auto_approve
      @order_request.approve!
    end

    render json: {
      success: true,
      message: 'Заявка успешно создана',
      request_number: @order_request.request_number,
      status: @order_request.status
    }, status: :created
  end
end
