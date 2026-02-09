# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin::Events', type: :request do
  let(:admin) { create(:user, :admin) }
  let(:client) { create(:user, :client) }
  let(:category) { create(:category) }

  describe 'authorization' do
    it 'redirects non-admin users' do
      sign_in(client)
      get admin_events_path
      expect(response).to redirect_to(root_path)
    end
  end

  context 'when authenticated as admin' do
    before { sign_in(admin) }

    describe 'GET /admin/events' do
      it 'returns successful response' do
        get admin_events_path
        expect(response).to have_http_status(:ok)
      end

      it 'displays all events' do
        published = create(:event, status: :published, title: 'Опубликованное')
        draft = create(:event, status: :draft, title: 'Черновик')

        get admin_events_path

        expect(response.body).to include('Опубликованное')
        expect(response.body).to include('Черновик')
      end

      it 'displays stats' do
        create_list(:event, 3, status: :published, starts_at: 1.day.from_now)
        create(:event, status: :published, starts_at: 1.day.ago)

        get admin_events_path

        expect(response.body).to include('Всего')
        expect(response.body).to include('Предстоящие')
        expect(response.body).to include('Прошедшие')
      end

      context 'with status filter' do
        it 'filters by status' do
          published = create(:event, status: :published, title: 'Публичное')
          draft = create(:event, status: :draft, title: 'Черновое')

          get admin_events_path, params: { status: 'published' }

          expect(response.body).to include('Публичное')
          expect(response.body).not_to include('Черновое')
        end
      end

      context 'with time filter' do
        it 'filters upcoming events' do
          upcoming = create(:event, starts_at: 1.day.from_now, title: 'Будущее')
          past = create(:event, starts_at: 1.day.ago, title: 'Прошлое')

          get admin_events_path, params: { time: 'upcoming' }

          expect(response.body).to include('Будущее')
          expect(response.body).not_to include('Прошлое')
        end
      end
    end

    describe 'GET /admin/events/:id' do
      let(:event) { create(:event) }

      it 'returns successful response' do
        get admin_event_path(event)
        expect(response).to have_http_status(:ok)
      end

      it 'displays event details' do
        get admin_event_path(event)
        expect(response.body).to include(event.title)
      end

      it 'displays recent registrations' do
        registration = create(:event_registration, event: event)

        get admin_event_path(event)
        expect(response.body).to include(registration.user.full_name)
      end
    end

    describe 'GET /admin/events/new' do
      it 'returns successful response' do
        get new_admin_event_path
        expect(response).to have_http_status(:ok)
      end

      it 'displays form' do
        get new_admin_event_path
        expect(response.body).to include('Название')
        expect(response.body).to include('Описание')
      end
    end

    describe 'POST /admin/events' do
      let(:valid_params) do
        {
          event: {
            title: 'Новое событие',
            description: 'Описание события',
            starts_at: 1.week.from_now,
            price_kopecks: 100_000,
            max_participants: 50,
            category_id: category.id,
            status: 'draft'
          }
        }
      end

      it 'creates event with valid params' do
        expect {
          post admin_events_path, params: valid_params
        }.to change(Event, :count).by(1)

        expect(response).to redirect_to(admin_event_path(Event.last))
      end

      it 'sets organizer to current user' do
        post admin_events_path, params: valid_params
        expect(Event.last.organizer).to eq(admin)
      end

      context 'with invalid params' do
        it 'renders form with errors' do
          post admin_events_path, params: { event: { title: '' } }
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    describe 'GET /admin/events/:id/edit' do
      let(:event) { create(:event) }

      it 'returns successful response' do
        get edit_admin_event_path(event)
        expect(response).to have_http_status(:ok)
      end
    end

    describe 'PATCH /admin/events/:id' do
      let(:event) { create(:event, title: 'Старое название') }

      it 'updates event' do
        patch admin_event_path(event), params: { event: { title: 'Новое название' } }

        expect(event.reload.title).to eq('Новое название')
        expect(response).to redirect_to(admin_event_path(event))
      end

      context 'with invalid params' do
        it 'renders form with errors' do
          patch admin_event_path(event), params: { event: { title: '' } }
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    describe 'DELETE /admin/events/:id' do
      let!(:event) { create(:event) }

      it 'destroys event' do
        expect {
          delete admin_event_path(event)
        }.to change(Event, :count).by(-1)

        expect(response).to redirect_to(admin_events_path)
      end
    end

    describe 'GET /admin/events/:id/registrations' do
      let(:event) { create(:event) }

      it 'returns successful response' do
        get registrations_admin_event_path(event)
        expect(response).to have_http_status(:ok)
      end

      it 'displays registrations' do
        registration = create(:event_registration, event: event, status: :confirmed)

        get registrations_admin_event_path(event)

        expect(response.body).to include(registration.user.full_name)
      end

      it 'displays registration stats' do
        create_list(:event_registration, 2, event: event, status: :confirmed)
        create(:event_registration, event: event, status: :pending)

        get registrations_admin_event_path(event)

        expect(response.body).to include('2') # confirmed count
      end
    end

    describe 'POST /admin/events/bulk_action' do
      let!(:event1) { create(:event, status: :draft) }
      let!(:event2) { create(:event, status: :draft) }

      it 'publishes selected events' do
        post bulk_action_admin_events_path, params: {
          bulk_action: 'publish',
          event_ids: [event1.id, event2.id]
        }

        expect(event1.reload.status_published?).to be true
        expect(event2.reload.status_published?).to be true
        expect(response).to redirect_to(admin_events_path)
      end

      it 'cancels selected events' do
        post bulk_action_admin_events_path, params: {
          bulk_action: 'cancel',
          event_ids: [event1.id]
        }

        expect(event1.reload.status_cancelled?).to be true
      end

      it 'deletes selected events' do
        expect {
          post bulk_action_admin_events_path, params: {
            bulk_action: 'delete',
            event_ids: [event1.id, event2.id]
          }
        }.to change(Event, :count).by(-2)
      end
    end
  end
end
