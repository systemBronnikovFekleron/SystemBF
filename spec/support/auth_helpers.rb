# frozen_string_literal: true

module AuthHelpers
  # Sign in user for request specs
  # Uses Authorization header which is always checked by ApplicationController
  def sign_in(user)
    @signed_in_user = user
    @jwt_token = JsonWebToken.encode(user_id: user.id)
  end

  # Override HTTP methods to auto-include auth headers
  [:get, :post, :patch, :put, :delete].each do |method|
    define_method(method) do |path, **args|
      if @jwt_token
        args[:headers] ||= {}
        args[:headers]['Authorization'] = "Bearer #{@jwt_token}"
      end
      super(path, **args)
    end
  end

  # Sign in user via API header (deprecated, use sign_in instead)
  def api_sign_in(user)
    token = JsonWebToken.encode(user_id: user.id)
    { 'Authorization' => "Bearer #{token}" }
  end

  # Generate HMAC signature for CloudPayments webhook
  def generate_cloudpayments_signature(order, amount = nil)
    api_secret = Rails.application.credentials.dig(:cloudpayments, :api_secret) || 'test_secret'
    amount ||= order.total_kopecks / 100.0

    data = [
      order.order_number,
      amount,
      'RUB',
      Time.current.utc.iso8601,
      '127.0.0.1',
      'RU',
      'Moscow',
      'Moscow',
      'Moscow',
      '55.7558',
      '37.6173',
      order.user.id,
      order.user.email,
      '424242',
      '4242',
      '12/25',
      'RU',
      'Test payment',
      nil
    ].compact.join('|')

    OpenSSL::HMAC.hexdigest('SHA256', api_secret, data)
  end

  # Build CloudPayments pay webhook params
  def cloudpayments_pay_params(order)
    {
      InvoiceId: order.order_number,
      Amount: order.total_kopecks / 100.0,
      Currency: 'RUB',
      DateTime: Time.current.utc.iso8601,
      IpAddress: '127.0.0.1',
      IpCountry: 'RU',
      IpCity: 'Moscow',
      IpRegion: 'Moscow',
      IpDistrict: 'Moscow',
      IpLatitude: '55.7558',
      IpLongitude: '37.6173',
      AccountId: order.user.id,
      Email: order.user.email,
      CardFirstSix: '424242',
      CardLastFour: '4242',
      CardExpDate: '12/25',
      IssuerBankCountry: 'RU',
      Description: 'Test payment',
      Data: nil,
      TransactionId: "test_#{SecureRandom.hex(8)}"
    }
  end
end

RSpec.configure do |config|
  config.include AuthHelpers, type: :request
  config.include AuthHelpers, type: :feature

  # Reset auth state between tests
  config.before(:each, type: :request) do
    @jwt_token = nil
    @signed_in_user = nil
  end
end
