# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EventReminderJob, type: :job do
  include ActiveJob::TestHelper

  let(:user) { create(:user) }
  let(:tomorrow) { 1.day.from_now }

  describe '#perform' do
    context 'when there are events happening tomorrow' do
      let!(:event) { create(:event, starts_at: tomorrow, status: :published) }
      let!(:registration) { create(:event_registration, event: event, user: user, status: :confirmed) }

      it 'sends reminder emails to registered users' do
        expect { described_class.new.perform }
          .to have_enqueued_mail(EventMailer, :reminder)
          .with(registration)
      end

      it 'logs the reminder' do
        allow(Rails.logger).to receive(:info)
        described_class.new.perform
        expect(Rails.logger).to have_received(:info).with(/Sent event reminder to #{user.email}/)
      end
    end

    context 'when events are not tomorrow' do
      let!(:event_today) { create(:event, starts_at: Time.current, status: :published) }
      let!(:event_next_week) { create(:event, starts_at: 1.week.from_now, status: :published) }

      it 'does not send reminders for today events' do
        create(:event_registration, event: event_today, user: user, status: :confirmed)

        expect { described_class.new.perform }
          .not_to have_enqueued_mail(EventMailer, :reminder)
      end

      it 'does not send reminders for next week events' do
        create(:event_registration, event: event_next_week, user: user, status: :confirmed)

        expect { described_class.new.perform }
          .not_to have_enqueued_mail(EventMailer, :reminder)
      end
    end

    context 'when event is not published' do
      let!(:draft_event) { create(:event, starts_at: tomorrow, status: :draft) }
      let!(:registration) { create(:event_registration, event: draft_event, user: user, status: :confirmed) }

      it 'does not send reminders for draft events' do
        expect { described_class.new.perform }
          .not_to have_enqueued_mail(EventMailer, :reminder)
      end
    end

    context 'when registration is cancelled' do
      let!(:event) { create(:event, starts_at: tomorrow, status: :published) }
      let!(:registration) { create(:event_registration, event: event, user: user, status: :cancelled) }

      it 'does not send reminders for cancelled registrations' do
        expect { described_class.new.perform }
          .not_to have_enqueued_mail(EventMailer, :reminder)
      end
    end
  end
end
