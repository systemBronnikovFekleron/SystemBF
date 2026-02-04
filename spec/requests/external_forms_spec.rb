# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'ExternalForms', type: :request do
  let(:product) { create(:product, price_kopecks: 100_000, status: 'published') }

  describe 'POST /external_forms/submit' do
    let(:valid_params) do
      {
        email: 'newuser@example.com',
        first_name: 'Иван',
        last_name: 'Иванов',
        phone: '+7 (999) 123-45-67',
        product_id: product.id
      }
    end

    context 'with valid params and new email' do
      it 'creates new user' do
        expect {
          post external_forms_submit_path, params: valid_params, as: :json
        }.to change { User.count }.by(1)
      end

      it 'creates order request' do
        expect {
          post external_forms_submit_path, params: valid_params, as: :json
        }.to change { OrderRequest.count }.by(1)
      end

      it 'sets user attributes correctly' do
        post external_forms_submit_path, params: valid_params, as: :json

        user = User.find_by(email: 'newuser@example.com')
        expect(user.first_name).to eq('Иван')
        expect(user.last_name).to eq('Иванов')
        expect(user.classification).to eq('client')
      end

      it 'returns success response' do
        post external_forms_submit_path, params: valid_params, as: :json

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['request_number']).to be_present
      end

      it 'sends welcome email' do
        expect {
          post external_forms_submit_path, params: valid_params, as: :json
        }.to have_enqueued_job(ActionMailer::MailDeliveryJob)
          .with('UserMailer', 'welcome_external_form', 'deliver_later', any_args)
      end
    end

    context 'with existing email' do
      let(:existing_user) { create(:user, email: 'existing@example.com') }

      before do
        existing_user
      end

      it 'does not create new user' do
        expect {
          post external_forms_submit_path, params: { **valid_params, email: existing_user.email }, as: :json
        }.not_to change { User.count }
      end

      it 'creates order request for existing user' do
        expect {
          post external_forms_submit_path, params: { **valid_params, email: existing_user.email }, as: :json
        }.to change { existing_user.order_requests.count }.by(1)
      end

      it 'does not send welcome email' do
        expect {
          post external_forms_submit_path, params: { **valid_params, email: existing_user.email }, as: :json
        }.not_to have_enqueued_job(ActionMailer::MailDeliveryJob)
          .with('UserMailer', 'welcome_external_form', any_args)
      end
    end

    context 'with auto_approve product' do
      before do
        product.update(auto_approve: true)
      end

      it 'auto-approves request' do
        post external_forms_submit_path, params: valid_params, as: :json

        request = OrderRequest.last
        expect(request.status).to eq('approved')
      end

      it 'returns approved status' do
        post external_forms_submit_path, params: valid_params, as: :json

        json = JSON.parse(response.body)
        expect(json['status']).to eq('approved')
      end
    end

    context 'without auto_approve' do
      it 'creates pending request' do
        post external_forms_submit_path, params: valid_params, as: :json

        request = OrderRequest.last
        expect(request.status).to eq('pending')
      end

      it 'returns pending status' do
        post external_forms_submit_path, params: valid_params, as: :json

        json = JSON.parse(response.body)
        expect(json['status']).to eq('pending')
      end
    end

    context 'with missing email' do
      it 'returns error' do
        post external_forms_submit_path, params: { product_id: product.id }, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['success']).to be false
        expect(json['error']).to be_present
      end

      it 'does not create user or request' do
        expect {
          post external_forms_submit_path, params: { product_id: product.id }, as: :json
        }.not_to change { [User.count, OrderRequest.count] }
      end
    end

    context 'with unpublished product' do
      let(:draft_product) { create(:product, status: 'draft') }

      it 'returns error' do
        post external_forms_submit_path, params: { **valid_params, product_id: draft_product.id }, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['success']).to be false
      end
    end

    context 'with custom form fields' do
      before do
        product.update(form_fields: [
          { 'name' => 'company_name', 'label' => 'Компания', 'field_type' => 'text', 'required' => true }
        ])
      end

      it 'saves custom fields in form_data' do
        post external_forms_submit_path, params: {
          **valid_params,
          company_name: 'ООО "Тест"'
        }, as: :json

        request = OrderRequest.last
        expect(request.form_data['company_name']).to eq('ООО "Тест"')
      end
    end
  end
end
