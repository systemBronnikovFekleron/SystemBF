# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Authentication', type: :request do
  let(:user) { create(:user, email: 'test@example.com', password: 'password123') }

  describe 'POST /api/v1/login' do
    context 'with valid credentials' do
      it 'returns a JWT token and user data' do
        user # создаем пользователя перед запросом
        post '/api/v1/login', params: { email: 'test@example.com', password: 'password123' }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['token']).to be_present
        expect(json['user']['email']).to eq('test@example.com')
      end

      it 'sets a JWT cookie' do
        user # создаем пользователя перед запросом
        post '/api/v1/login', params: { email: 'test@example.com', password: 'password123' }

        expect(response.cookies['jwt_token']).to be_present
      end
    end

    context 'with invalid credentials' do
      it 'returns unauthorized error' do
        post '/api/v1/login', params: { email: 'test@example.com', password: 'wrongpassword' }

        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Invalid credentials')
      end
    end

    context 'with non-existent user' do
      it 'returns unauthorized error' do
        post '/api/v1/login', params: { email: 'nonexistent@example.com', password: 'password123' }

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'DELETE /api/v1/logout' do
    it 'clears the JWT cookie' do
      delete '/api/v1/logout'

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['message']).to eq('Logged out successfully')
    end
  end

  describe 'GET /api/v1/validate_token' do
    context 'with valid token' do
      it 'returns user data' do
        token = JsonWebToken.encode(user_id: user.id)

        get '/api/v1/validate_token', headers: { 'Authorization' => "Bearer #{token}" }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['valid']).to be true
        expect(json['user']['email']).to eq(user.email)
      end
    end

    context 'with invalid token' do
      it 'returns unauthorized error' do
        get '/api/v1/validate_token', headers: { 'Authorization' => 'Bearer invalid_token' }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'without token' do
      it 'returns unauthorized error' do
        get '/api/v1/validate_token'

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
