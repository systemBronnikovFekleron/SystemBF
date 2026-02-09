# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EventMailer, type: :mailer do
  let(:user) { create(:user, first_name: 'Иван', email: 'ivan@example.com') }
  let(:event) { create(:event, title: 'Тестовое событие', starts_at: 1.day.from_now, is_online: true) }
  let(:registration) { create(:event_registration, user: user, event: event) }

  describe '#reminder' do
    let(:mail) { described_class.reminder(registration) }

    it 'renders the subject' do
      expect(mail.subject).to eq("Напоминание: #{event.title} — завтра!")
    end

    it 'renders the receiver email' do
      expect(mail.to).to eq([user.email])
    end

    it 'renders the sender email' do
      expect(mail.from).to eq(['noreply@bronnikov.com'])
    end

    it 'contains event title' do
      expect(mail.body.encoded).to include(event.title)
    end

    it 'contains user name' do
      expect(mail.body.encoded).to include('Иван')
    end

    it 'contains reminder text' do
      expect(mail.body.encoded).to include('завтра')
    end
  end

  describe '#registration_confirmation' do
    let(:mail) { described_class.registration_confirmation(registration) }

    it 'renders the subject' do
      expect(mail.subject).to eq("Вы зарегистрированы на #{event.title}")
    end

    it 'renders the receiver email' do
      expect(mail.to).to eq([user.email])
    end

    it 'contains event title' do
      expect(mail.body.encoded).to include(event.title)
    end

    it 'contains confirmation text' do
      expect(mail.body.encoded).to include('успешно зарегистрированы')
    end
  end

  describe '#cancellation' do
    let(:mail) { described_class.cancellation(registration) }

    it 'renders the subject' do
      expect(mail.subject).to eq("Отмена регистрации: #{event.title}")
    end

    it 'renders the receiver email' do
      expect(mail.to).to eq([user.email])
    end

    it 'contains event title' do
      expect(mail.body.encoded).to include(event.title)
    end

    it 'contains cancellation text' do
      expect(mail.body.encoded).to include('отменена')
    end
  end
end
