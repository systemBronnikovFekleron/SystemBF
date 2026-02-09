# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DiagnosticMailer, type: :mailer do
  let(:user) { create(:user, first_name: 'Иван', email: 'ivan@example.com') }
  let(:specialist) { create(:user, first_name: 'Мария', last_name: 'Петрова') }
  let(:diagnostic) do
    create(:diagnostic,
           user: user,
           conducted_by: specialist,
           diagnostic_type: 'vision',
           conducted_at: 1.day.from_now,
           status: :scheduled)
  end

  describe '#reminder' do
    let(:mail) { described_class.reminder(diagnostic) }

    it 'renders the subject' do
      expect(mail.subject).to include('Напоминание')
      expect(mail.subject).to include('завтра')
    end

    it 'renders the receiver email' do
      expect(mail.to).to eq([user.email])
    end

    it 'renders the sender email' do
      expect(mail.from).to eq(['noreply@bronnikov.com'])
    end

    it 'contains diagnostic type' do
      expect(mail.body.encoded).to include('Видение')
    end

    it 'contains user name' do
      expect(mail.body.encoded).to include('Иван')
    end

    it 'contains specialist name' do
      expect(mail.body.encoded).to include('Мария')
      expect(mail.body.encoded).to include('Петрова')
    end

    it 'contains preparation tips' do
      expect(mail.body.encoded).to include('Подготовка к диагностике')
    end
  end

  describe '#scheduled' do
    let(:mail) { described_class.scheduled(diagnostic) }

    it 'renders the subject' do
      expect(mail.subject).to include('назначена')
    end

    it 'renders the receiver email' do
      expect(mail.to).to eq([user.email])
    end

    it 'contains diagnostic type' do
      expect(mail.body.encoded).to include('Видение')
    end

    it 'contains reminder notice' do
      expect(mail.body.encoded).to include('напоминание')
    end
  end

  describe '#completed' do
    let(:completed_diagnostic) do
      create(:diagnostic,
             user: user,
             conducted_by: specialist,
             diagnostic_type: 'bioenergy',
             conducted_at: 1.day.ago,
             status: :completed,
             score: 85,
             recommendations: 'Рекомендуется продолжить занятия')
    end
    let(:mail) { described_class.completed(completed_diagnostic) }

    it 'renders the subject' do
      expect(mail.subject).to include('завершена')
    end

    it 'renders the receiver email' do
      expect(mail.to).to eq([user.email])
    end

    it 'contains diagnostic type' do
      expect(mail.body.encoded).to include('Биоэнергетика')
    end

    it 'contains score' do
      expect(mail.body.encoded).to include('85')
    end

    it 'contains recommendations' do
      expect(mail.body.encoded).to include('Рекомендуется продолжить занятия')
    end
  end
end
