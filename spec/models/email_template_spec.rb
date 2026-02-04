# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EmailTemplate, type: :model do
  # Associations
  describe 'associations' do
    it { should belong_to(:updated_by).class_name('User').optional }
  end

  # Validations
  describe 'validations' do
    subject { build(:email_template) }

    it { should validate_presence_of(:template_key) }
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:subject) }
    it { should validate_presence_of(:body_html) }
    it { should validate_uniqueness_of(:template_key) }
    it do
      should validate_inclusion_of(:category)
        .in_array(%w[user order product system])
        .allow_nil
    end
  end

  # Scopes
  describe 'scopes' do
    let!(:active_template) { create(:email_template, active: true) }
    let!(:inactive_template) { create(:email_template, :inactive) }
    let!(:system_template) { create(:email_template, :system) }
    let!(:user_template) { create(:email_template, :user_category) }

    it '.active returns only active templates' do
      expect(described_class.active).to include(active_template)
      expect(described_class.active).not_to include(inactive_template)
    end

    it '.inactive returns only inactive templates' do
      expect(described_class.inactive).to include(inactive_template)
      expect(described_class.inactive).not_to include(active_template)
    end

    it '.system_defaults returns only system templates' do
      expect(described_class.system_defaults).to include(system_template)
      expect(described_class.system_defaults).not_to include(active_template)
    end

    it '.by_category filters by category' do
      expect(described_class.by_category('user')).to include(user_template)
    end
  end

  # Instance methods
  describe '#render_subject' do
    let(:template) { create(:email_template, subject: 'Привет, {{user_name}}!') }

    it 'renders subject with variables' do
      result = template.render_subject(user_name: 'Иван')
      expect(result).to eq('Привет, Иван!')
    end

    it 'leaves unreplaced variables as is' do
      result = template.render_subject(other: 'value')
      expect(result).to eq('Привет, {{user_name}}!')
    end
  end

  describe '#render_body_html' do
    let(:template) do
      create(:email_template,
             body_html: '<p>Привет, {{user_name}}! Email: {{user_email}}</p>')
    end

    it 'renders body with multiple variables' do
      result = template.render_body_html(user_name: 'Иван', user_email: 'ivan@example.com')
      expect(result).to eq('<p>Привет, Иван! Email: ivan@example.com</p>')
    end
  end

  describe '#render_body_text' do
    let(:template) do
      create(:email_template,
             body_text: 'Привет, {{user_name}}!')
    end

    it 'renders text body with variables' do
      result = template.render_body_text(user_name: 'Иван')
      expect(result).to eq('Привет, Иван!')
    end

    it 'returns nil when body_text is blank' do
      template.body_text = nil
      expect(template.render_body_text(user_name: 'Иван')).to be_nil
    end
  end

  describe '#increment_sent!' do
    let(:template) { create(:email_template) }

    it 'increments sent count' do
      expect { template.increment_sent! }
        .to change { template.reload.sent_count }.by(1)
    end

    it 'updates last_sent_at' do
      expect { template.increment_sent! }
        .to change { template.reload.last_sent_at }
    end
  end

  describe '#duplicate!' do
    let(:template) { create(:email_template, :user_category) }

    it 'creates a new template with same content' do
      new_template = template.duplicate!('new_key', 'New Template')
      expect(new_template.template_key).to eq('new_key')
      expect(new_template.name).to eq('New Template')
      expect(new_template.body_html).to eq(template.body_html)
      expect(new_template.subject).to eq(template.subject)
    end

    it 'creates inactive non-system template' do
      new_template = template.duplicate!('new_key', 'New Template')
      expect(new_template.active).to be false
      expect(new_template.system_default).to be false
    end
  end

  describe 'system template protection' do
    it 'prevents deletion of system templates' do
      system_template = create(:email_template, :system)
      result = system_template.destroy
      expect(result).to be false
      expect(system_template.errors[:base]).to include('Нельзя удалить системный шаблон')
      expect(described_class.exists?(system_template.id)).to be true
    end

    it 'allows deletion of custom templates' do
      custom_template = create(:email_template)
      expect { custom_template.destroy }.to change { described_class.count }.by(-1)
      expect(described_class.exists?(custom_template.id)).to be false
    end
  end
end
