# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Events - Browsing', type: :request do
  describe 'GET /events' do
    it 'returns successful response' do
      get events_path
      expect(response).to have_http_status(:ok)
    end

    it 'displays published upcoming events' do
      published = create(:event, status: :published, starts_at: 1.day.from_now)

      get events_path

      expect(response.body).to include(published.title)
    end
  end

  describe 'GET /events/:id' do
    let(:event) { create(:event, status: :published) }

    it 'returns successful response' do
      get event_path(event)
      expect(response).to have_http_status(:ok)
    end

    it 'displays event details' do
      get event_path(event)
      expect(response.body).to include(event.title)
    end
  end

  describe 'GET /events/calendar' do
    it 'returns successful response' do
      get calendar_events_path
      expect(response).to have_http_status(:ok)
    end

    it 'displays events' do
      event = create(:event, status: :published, starts_at: 1.week.from_now)

      get calendar_events_path
      expect(response.body).to include(event.title)
    end
  end
end
