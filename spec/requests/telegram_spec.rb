require 'rails_helper'

RSpec.describe "Telegrams", type: :request do
  describe "GET /link" do
    it "returns http success" do
      get "/telegram/link"
      expect(response).to have_http_status(:success)
    end
  end

end
