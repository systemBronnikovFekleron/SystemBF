# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin::EmailTemplates', type: :request do
  let(:admin) { create(:user, classification: :admin) }
  let(:regular_user) { create(:user, classification: :client) }
  let(:email_template) { create(:email_template) }

  describe 'GET /admin/email_templates' do
    context 'as admin' do
      before { sign_in admin }

      it 'returns success' do
        get admin_email_templates_path
        expect(response).to have_http_status(:success)
      end

      it 'displays all templates' do
        create(:email_template, name: 'Template 1')
        create(:email_template, name: 'Template 2')
        get admin_email_templates_path
        expect(response.body).to include('Template 1')
        expect(response.body).to include('Template 2')
      end

      it 'filters by category' do
        user_template = create(:email_template, :user_category)
        create(:email_template, :order_category)

        get admin_email_templates_path, params: { category: 'user' }
        expect(response).to have_http_status(:success)
      end

      it 'filters by active status' do
        create(:email_template, active: true)
        create(:email_template, :inactive)

        get admin_email_templates_path, params: { active: 'true' }
        expect(response).to have_http_status(:success)
      end
    end

    context 'as regular user' do
      before { sign_in regular_user }

      it 'denies access' do
        get admin_email_templates_path
        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to include('нет прав')
      end
    end

    context 'as guest' do
      it 'redirects to login' do
        get admin_email_templates_path
        expect(response).to redirect_to(login_path)
      end
    end
  end

  describe 'GET /admin/email_templates/:id' do
    before { sign_in admin }

    it 'returns success' do
      get admin_email_template_path(email_template)
      expect(response).to have_http_status(:success)
    end

    it 'displays template details' do
      get admin_email_template_path(email_template)
      expect(response.body).to include(email_template.name)
      expect(response.body).to include(email_template.subject)
    end
  end

  describe 'GET /admin/email_templates/new' do
    before { sign_in admin }

    it 'returns success' do
      get new_admin_email_template_path
      expect(response).to have_http_status(:success)
    end

    it 'displays form' do
      get new_admin_email_template_path
      expect(response.body).to include('form')
    end
  end

  describe 'POST /admin/email_templates' do
    before { sign_in admin }

    context 'with valid params' do
      let(:valid_params) do
        {
          email_template: {
            template_key: 'test_template',
            name: 'Test Template',
            category: 'user',
            subject: 'Test Subject {{name}}',
            body_html: '<p>Test Body {{name}}</p>',
            body_text: 'Test Body {{name}}',
            available_variables: ['name', 'email']
          }
        }
      end

      it 'creates a new template' do
        expect do
          post admin_email_templates_path, params: valid_params
        end.to change(EmailTemplate, :count).by(1)
      end

      it 'redirects to show page' do
        post admin_email_templates_path, params: valid_params
        expect(response).to redirect_to(admin_email_template_path(EmailTemplate.last))
      end

      it 'displays success notice' do
        post admin_email_templates_path, params: valid_params
        follow_redirect!
        expect(response.body).to include('успешно создан')
      end

      it 'sets updated_by to current user' do
        post admin_email_templates_path, params: valid_params
        expect(EmailTemplate.last.updated_by).to eq(admin)
      end
    end

    context 'with invalid params' do
      let(:invalid_params) do
        {
          email_template: {
            template_key: '',
            name: '',
            subject: '',
            body_html: ''
          }
        }
      end

      it 'does not create template' do
        expect do
          post admin_email_templates_path, params: invalid_params
        end.not_to change(EmailTemplate, :count)
      end

      it 'renders new template' do
        post admin_email_templates_path, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'GET /admin/email_templates/:id/edit' do
    before { sign_in admin }

    it 'returns success' do
      get edit_admin_email_template_path(email_template)
      expect(response).to have_http_status(:success)
    end

    it 'displays edit form' do
      get edit_admin_email_template_path(email_template)
      expect(response.body).to include('form')
      expect(response.body).to include(email_template.name)
    end
  end

  describe 'PATCH /admin/email_templates/:id' do
    before { sign_in admin }

    context 'with valid params' do
      let(:valid_params) do
        {
          email_template: {
            name: 'Updated Name',
            subject: 'Updated Subject'
          }
        }
      end

      it 'updates the template' do
        patch admin_email_template_path(email_template), params: valid_params
        email_template.reload
        expect(email_template.name).to eq('Updated Name')
        expect(email_template.subject).to eq('Updated Subject')
      end

      it 'redirects to show page' do
        patch admin_email_template_path(email_template), params: valid_params
        expect(response).to redirect_to(admin_email_template_path(email_template))
      end

      it 'updates updated_by' do
        patch admin_email_template_path(email_template), params: valid_params
        expect(email_template.reload.updated_by).to eq(admin)
      end
    end

    context 'with invalid params' do
      let(:invalid_params) do
        {
          email_template: {
            name: '',
            subject: ''
          }
        }
      end

      it 'does not update template' do
        original_name = email_template.name
        patch admin_email_template_path(email_template), params: invalid_params
        expect(email_template.reload.name).to eq(original_name)
      end

      it 'renders edit template' do
        patch admin_email_template_path(email_template), params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'DELETE /admin/email_templates/:id' do
    before { sign_in admin }

    context 'for custom template' do
      let(:custom_template) { create(:email_template) }

      it 'deletes the template' do
        custom_template # create it
        expect do
          delete admin_email_template_path(custom_template)
        end.to change(EmailTemplate, :count).by(-1)
      end

      it 'redirects to index' do
        delete admin_email_template_path(custom_template)
        expect(response).to redirect_to(admin_email_templates_path)
      end
    end

    context 'for system template' do
      let(:system_template) { create(:email_template, :system) }

      it 'does not delete the template' do
        system_template # create it
        expect do
          delete admin_email_template_path(system_template)
        end.not_to change(EmailTemplate, :count)
      end

      it 'displays error message' do
        delete admin_email_template_path(system_template)
        follow_redirect!
        expect(response.body).to include('Нельзя удалить системный шаблон')
      end
    end
  end

  describe 'GET /admin/email_templates/:id/preview' do
    before { sign_in admin }

    it 'returns success' do
      get preview_admin_email_template_path(email_template)
      expect(response).to have_http_status(:success)
    end

    it 'displays preview content' do
      get preview_admin_email_template_path(email_template)
      expect(response.body).to include('Preview')
    end

    it 'accepts variables for preview' do
      get preview_admin_email_template_path(email_template),
          params: { variables: { user_name: 'Test User' } }
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST /admin/email_templates/:id/send_test' do
    before { sign_in admin }

    context 'with successful delivery' do
      before do
        allow_any_instance_of(EmailTemplate).to receive(:send_test_email)
          .and_return({ success: true, message: 'Test email sent' })
      end

      it 'displays success message' do
        post send_test_admin_email_template_path(email_template),
             params: { recipient_email: 'test@example.com' }
        follow_redirect!
        expect(response.body).to include('Test email sent')
      end
    end

    context 'with failed delivery' do
      before do
        allow_any_instance_of(EmailTemplate).to receive(:send_test_email)
          .and_return({ success: false, message: 'Delivery failed' })
      end

      it 'displays error message' do
        post send_test_admin_email_template_path(email_template),
             params: { recipient_email: 'test@example.com' }
        follow_redirect!
        expect(response.body).to include('Delivery failed')
      end
    end

    it 'uses current user email if not specified' do
      expect_any_instance_of(EmailTemplate).to receive(:send_test_email)
        .with(admin.email, {})
        .and_return({ success: true, message: 'Sent' })

      post send_test_admin_email_template_path(email_template)
    end
  end

  describe 'POST /admin/email_templates/:id/duplicate' do
    before { sign_in admin }

    it 'creates a duplicate template' do
      expect do
        post duplicate_admin_email_template_path(email_template)
      end.to change(EmailTemplate, :count).by(1)
    end

    it 'redirects to edit page of new template' do
      post duplicate_admin_email_template_path(email_template)
      new_template = EmailTemplate.last
      expect(response).to redirect_to(edit_admin_email_template_path(new_template))
    end

    it 'creates inactive copy' do
      post duplicate_admin_email_template_path(email_template)
      new_template = EmailTemplate.last
      expect(new_template.active).to be false
      expect(new_template.system_default).to be false
    end

    it 'preserves content' do
      post duplicate_admin_email_template_path(email_template)
      new_template = EmailTemplate.last
      expect(new_template.body_html).to eq(email_template.body_html)
      expect(new_template.subject).to eq(email_template.subject)
    end
  end
end
