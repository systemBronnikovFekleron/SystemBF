# frozen_string_literal: true

module Admin
  class EmailTemplatesController < BaseController
    before_action :set_email_template, only: [:show, :edit, :update, :destroy, :preview, :send_test, :duplicate]

    def index
      authorize EmailTemplate
      @email_templates = policy_scope(EmailTemplate)
                          .order(system_default: :desc, created_at: :desc)
                          .page(params[:page])
                          .per(20)

      @filter_category = params[:category]
      @email_templates = @email_templates.by_category(@filter_category) if @filter_category.present?

      @filter_active = params[:active]
      if @filter_active == 'true'
        @email_templates = @email_templates.active
      elsif @filter_active == 'false'
        @email_templates = @email_templates.inactive
      end
    end

    def show
      authorize @email_template
    end

    def new
      @email_template = EmailTemplate.new
      authorize @email_template
    end

    def create
      @email_template = EmailTemplate.new(email_template_params)
      @email_template.updated_by = current_user
      authorize @email_template

      if @email_template.save
        redirect_to admin_email_template_path(@email_template),
                    notice: 'Email шаблон успешно создан.'
      else
        flash.now[:alert] = 'Ошибка при создании шаблона.'
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize @email_template
    end

    def update
      authorize @email_template
      @email_template.updated_by = current_user

      if @email_template.update(email_template_params)
        redirect_to admin_email_template_path(@email_template),
                    notice: 'Email шаблон успешно обновлен.'
      else
        flash.now[:alert] = 'Ошибка при обновлении шаблона.'
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @email_template

      if @email_template.destroy
        redirect_to admin_email_templates_path,
                    notice: 'Email шаблон успешно удален.'
      else
        redirect_to admin_email_template_path(@email_template),
                    alert: @email_template.errors.full_messages.join(', ')
      end
    end

    def preview
      authorize @email_template, :preview?

      # Генерируем тестовые данные для preview
      @variables = params[:variables] || {}
      @preview_subject = @email_template.render_subject(@variables)
      @preview_body_html = @email_template.render_body_html(@variables)
      @preview_body_text = @email_template.render_body_text(@variables)

      render layout: false
    end

    def send_test
      authorize @email_template, :send_test?

      recipient = params[:recipient_email] || current_user.email
      test_variables = params[:variables] || {}

      result = @email_template.send_test_email(recipient, test_variables)

      if result[:success]
        redirect_to admin_email_template_path(@email_template),
                    notice: result[:message]
      else
        redirect_to admin_email_template_path(@email_template),
                    alert: result[:message]
      end
    end

    def duplicate
      authorize @email_template, :duplicate?

      new_key = "#{@email_template.template_key}_copy_#{Time.current.to_i}"
      new_name = "#{@email_template.name} (Копия)"

      begin
        new_template = @email_template.duplicate!(new_key, new_name)
        redirect_to edit_admin_email_template_path(new_template),
                    notice: 'Шаблон успешно дублирован.'
      rescue ActiveRecord::RecordInvalid => e
        redirect_to admin_email_template_path(@email_template),
                    alert: "Ошибка дублирования: #{e.message}"
      end
    end

    private

    def set_email_template
      @email_template = EmailTemplate.find(params[:id])
    end

    def email_template_params
      params.require(:email_template).permit(
        :template_key,
        :name,
        :category,
        :subject,
        :body_html,
        :body_text,
        :active,
        available_variables: []
      )
    end
  end
end
