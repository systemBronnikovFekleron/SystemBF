# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Events - Registration', type: :request do
  let(:user) { create(:user, :client) }

  describe 'POST /events/:event_id/register' do
    context 'when not authenticated' do
      it 'redirects to login' do
        event = create(:event, :free, status: :published)
        post event_event_registrations_path(event)
        expect(response).to redirect_to(login_path)
      end
    end

    context 'when authenticated' do
      before { sign_in(user) }

      context 'for free event' do
        let(:event) { create(:event, :free, status: :published) }

        it 'creates confirmed registration' do
          expect {
            post event_event_registrations_path(event)
          }.to change(EventRegistration, :count).by(1)

          expect(EventRegistration.last.status_confirmed?).to be true
          expect(response).to redirect_to(event_path(event))
        end

        it 'sets correct flash message' do
          post event_event_registrations_path(event)
          follow_redirect!
          expect(response.body).to include('успешно зарегистрированы')
        end
      end

      context 'for paid event' do
        let(:paid_event) { create(:event, status: :published, price_kopecks: 100_000) }

        it 'creates pending registration and order' do
          expect {
            post event_event_registrations_path(paid_event)
          }.to change(EventRegistration, :count).by(1)
             .and change(Order, :count).by(1)

          expect(EventRegistration.last.status_pending?).to be true
          expect(response).to redirect_to(new_order_payment_path(Order.last))
        end
      end

      context 'when already registered' do
        let(:event) { create(:event, :free, status: :published) }

        before { create(:event_registration, user: user, event: event) }

        it 'does not create duplicate registration' do
          expect {
            post event_event_registrations_path(event)
          }.not_to change(EventRegistration, :count)

          follow_redirect!
          expect(response.body).to include('уже зарегистрированы')
        end
      end

      context 'when event is full' do
        let(:full_event) { create(:event, :free, status: :published, max_participants: 1) }

        before { create(:event_registration, event: full_event, status: :confirmed) }

        it 'does not allow registration' do
          expect {
            post event_event_registrations_path(full_event)
          }.not_to change(EventRegistration, :count)

          follow_redirect!
          expect(response.body).to include('места заняты')
        end
      end
    end
  end

  describe 'DELETE /registrations/:id' do
    before { sign_in(user) }

    it 'cancels user registration' do
      event = create(:event, status: :published)
      registration = create(:event_registration, user: user, event: event, status: :confirmed)

      delete event_registration_path(registration)

      expect(registration.reload.status_cancelled?).to be true
      expect(response).to redirect_to(dashboard_events_path)
    end

    it 'cannot cancel other user registration' do
      event = create(:event, status: :published)
      other_user = create(:user)
      registration = create(:event_registration, user: other_user, event: event)

      delete event_registration_path(registration)

      expect(response).to have_http_status(:not_found)
    end
  end
end
