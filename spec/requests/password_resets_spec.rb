# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Password Resets', type: :request do
  let(:user) { create(:user, email: 'test@example.com') }

  describe 'GET /forgot-password' do
    it 'shows password reset request form' do
      get new_password_reset_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Восстановление пароля')
      expect(response.body).to include('Введите email')
    end
  end

  describe 'POST /password-resets' do
    context 'with valid email' do
      it 'creates reset token' do
        post password_resets_path, params: { email: user.email }

        user.reload
        expect(user.reset_password_token).to be_present
        expect(user.reset_password_sent_at).to be_present
      end

      it 'sends password reset email' do
        expect {
          post password_resets_path, params: { email: user.email }
        }.to have_enqueued_job.on_queue('default')
      end

      it 'redirects with success notice' do
        post password_resets_path, params: { email: user.email }

        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to include('Инструкции по восстановлению пароля отправлены')
      end
    end

    context 'with invalid email' do
      it 'shows error message' do
        post password_resets_path, params: { email: 'nonexistent@example.com' }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include('Email не найден')
      end

      it 'does not send email' do
        expect {
          post password_resets_path, params: { email: 'nonexistent@example.com' }
        }.not_to have_enqueued_job
      end
    end
  end

  describe 'GET /password-reset/:token/edit' do
    context 'with valid token' do
      before do
        user.create_reset_password_token!
      end

      it 'shows password reset form' do
        get edit_password_reset_path(token: user.reset_password_token)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Создайте новый пароль')
      end
    end

    context 'with invalid token' do
      it 'redirects with error' do
        get edit_password_reset_path(token: 'invalid_token')

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include('Неверная ссылка')
      end
    end

    context 'with expired token' do
      before do
        user.create_reset_password_token!
        user.update_column(:reset_password_sent_at, 25.hours.ago)
      end

      it 'redirects with expiration error' do
        get edit_password_reset_path(token: user.reset_password_token)

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include('Ссылка для восстановления пароля истекла')
      end
    end
  end

  describe 'PATCH /password-reset/:token' do
    before do
      user.create_reset_password_token!
    end

    context 'with valid password' do
      it 'updates user password' do
        patch password_reset_path(token: user.reset_password_token), params: {
          password: 'newpassword123',
          password_confirmation: 'newpassword123'
        }

        user.reload
        expect(user.authenticate('newpassword123')).to eq(user)
      end

      it 'clears reset token' do
        patch password_reset_path(token: user.reset_password_token), params: {
          password: 'newpassword123',
          password_confirmation: 'newpassword123'
        }

        user.reload
        expect(user.reset_password_token).to be_nil
        expect(user.reset_password_sent_at).to be_nil
      end

      it 'redirects to login with success message' do
        patch password_reset_path(token: user.reset_password_token), params: {
          password: 'newpassword123',
          password_confirmation: 'newpassword123'
        }

        expect(response).to redirect_to(login_path)
        expect(flash[:notice]).to include('Пароль успешно изменен')
      end
    end

    context 'with mismatched passwords' do
      it 'shows error message' do
        patch password_reset_path(token: user.reset_password_token), params: {
          password: 'newpassword123',
          password_confirmation: 'differentpassword'
        }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include('Пароли не совпадают')
      end

      it 'does not update password' do
        old_password_digest = user.password_digest

        patch password_reset_path(token: user.reset_password_token), params: {
          password: 'newpassword123',
          password_confirmation: 'differentpassword'
        }

        user.reload
        expect(user.password_digest).to eq(old_password_digest)
      end
    end

    context 'with blank password' do
      it 'shows error message' do
        patch password_reset_path(token: user.reset_password_token), params: {
          password: '',
          password_confirmation: ''
        }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include('Пароль не может быть пустым')
      end
    end

    context 'with invalid token' do
      it 'redirects with error' do
        patch password_reset_path(token: 'invalid_token'), params: {
          password: 'newpassword123',
          password_confirmation: 'newpassword123'
        }

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include('Неверная ссылка')
      end
    end

    context 'with expired token' do
      before do
        user.update_column(:reset_password_sent_at, 25.hours.ago)
      end

      it 'redirects with expiration error' do
        patch password_reset_path(token: user.reset_password_token), params: {
          password: 'newpassword123',
          password_confirmation: 'newpassword123'
        }

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include('Ссылка для восстановления пароля истекла')
      end

      it 'does not update password' do
        old_password_digest = user.password_digest

        patch password_reset_path(token: user.reset_password_token), params: {
          password: 'newpassword123',
          password_confirmation: 'newpassword123'
        }

        user.reload
        expect(user.password_digest).to eq(old_password_digest)
      end
    end
  end
end
