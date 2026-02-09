# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DiagnosticReminderJob, type: :job do
  include ActiveJob::TestHelper

  let(:user) { create(:user) }
  let(:specialist) { create(:user) }
  let(:tomorrow) { 1.day.from_now }

  describe '#perform' do
    context 'when there are diagnostics scheduled for tomorrow' do
      let!(:diagnostic) do
        create(:diagnostic,
               user: user,
               conducted_by: specialist,
               conducted_at: tomorrow,
               status: :scheduled)
      end

      it 'sends reminder emails to users' do
        expect { described_class.new.perform }
          .to have_enqueued_mail(DiagnosticMailer, :reminder)
          .with(diagnostic)
      end

      it 'logs the reminder' do
        allow(Rails.logger).to receive(:info)
        described_class.new.perform
        expect(Rails.logger).to have_received(:info).with(/Sent diagnostic reminder to #{user.email}/)
      end
    end

    context 'when diagnostics are not tomorrow' do
      let!(:diagnostic_today) do
        create(:diagnostic,
               user: user,
               conducted_at: Time.current,
               status: :scheduled)
      end

      let!(:diagnostic_next_week) do
        create(:diagnostic,
               user: user,
               conducted_at: 1.week.from_now,
               status: :scheduled)
      end

      it 'does not send reminders for today diagnostics' do
        expect { described_class.new.perform }
          .not_to have_enqueued_mail(DiagnosticMailer, :reminder)
      end
    end

    context 'when diagnostic is already completed' do
      let!(:completed_diagnostic) do
        create(:diagnostic,
               user: user,
               conducted_at: tomorrow,
               status: :completed)
      end

      it 'does not send reminders for completed diagnostics' do
        expect { described_class.new.perform }
          .not_to have_enqueued_mail(DiagnosticMailer, :reminder)
      end
    end

    context 'when diagnostic is cancelled' do
      let!(:cancelled_diagnostic) do
        create(:diagnostic,
               user: user,
               conducted_at: tomorrow,
               status: :cancelled)
      end

      it 'does not send reminders for cancelled diagnostics' do
        expect { described_class.new.perform }
          .not_to have_enqueued_mail(DiagnosticMailer, :reminder)
      end
    end
  end
end
