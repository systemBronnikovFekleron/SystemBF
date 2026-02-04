require 'rails_helper'

RSpec.describe "Webhooks::Telegrams", type: :request do
  describe "GET /webhook" do
    it "returns http success" do
      get "/webhooks/telegram/webhook"
      expect(response).to have_http_status(:success)
    end
  end

end
