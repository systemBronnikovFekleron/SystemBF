# frozen_string_literal: true

module ApplicationHelper
  include ProductsHelper

  def user_signed_in?
    session[:user_id].present?
  end

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def classification_badge(classification)
    labels = {
      'guest' => 'Гость',
      'client' => 'Клиент',
      'club_member' => 'Участник клуба',
      'representative' => 'Представитель',
      'trainee' => 'Стажер',
      'instructor_1' => 'Инструктор 1 кат',
      'instructor_2' => 'Инструктор 2 кат',
      'instructor_3' => 'Инструктор 3 кат',
      'specialist' => 'Специалист',
      'expert' => 'Эксперт',
      'center_director' => 'Директор центра',
      'curator' => 'Куратор',
      'manager' => 'Менеджер',
      'admin' => 'Администратор'
    }

    content_tag(:span, labels[classification] || classification, class: 'badge badge-primary')
  end

  def format_currency(amount_kopecks)
    Money.new(amount_kopecks, 'RUB').format
  end

  def pluralize(count, one, few, many)
    return "#{count} #{many}" if (count % 100).between?(11, 14)

    case count % 10
    when 1 then "#{count} #{one}"
    when 2..4 then "#{count} #{few}"
    else "#{count} #{many}"
    end
  end

  def order_status_style(status)
    case status.to_s
    when 'pending'
      'background: rgba(245, 158, 11, 0.2); color: #F59E0B;'
    when 'paid', 'completed'
      'background: rgba(34, 197, 94, 0.2); color: #22C55E;'
    when 'cancelled'
      'background: rgba(239, 68, 68, 0.2); color: #EF4444;'
    when 'refunded'
      'background: rgba(168, 85, 247, 0.2); color: #A855F7;'
    else
      'background: rgba(148, 163, 184, 0.2); color: #94A3B8;'
    end
  end

  def product_type_label(product_type)
    {
      'video_course' => 'Видеокурс',
      'book' => 'Книга',
      'course' => 'Курс',
      'service' => 'Услуга',
      'event' => 'Мероприятие'
    }[product_type] || product_type
  end

  def duration_to_human(minutes)
    return unless minutes

    hours = minutes / 60
    mins = minutes % 60

    if hours > 0 && mins > 0
      "#{hours} ч #{mins} мин"
    elsif hours > 0
      "#{hours} ч"
    else
      "#{mins} мин"
    end
  end

  def classification_label(classification)
    t("user_classification.#{classification}")
  end

  def classification_badge_style(classification)
    case classification.to_s
    when 'admin', 'manager', 'curator'
      'background: rgba(239, 68, 68, 0.1); color: #DC2626;'
    when 'center_director'
      'background: rgba(168, 85, 247, 0.1); color: #9333EA;'
    when 'specialist', 'expert'
      'background: rgba(14, 165, 233, 0.1); color: #0ea5e9;'
    when 'instructor_1', 'instructor_2', 'instructor_3'
      'background: rgba(34, 197, 94, 0.1); color: #16A34A;'
    when 'client', 'club_member', 'representative', 'trainee'
      'background: rgba(245, 158, 11, 0.1); color: #D97706;'
    when 'guest'
      'background: rgba(148, 163, 184, 0.1); color: #64748B;'
    else
      'background: rgba(148, 163, 184, 0.1); color: #64748B;'
    end
  end

  def status_badge_style(status)
    case status.to_s
    when 'published'
      'background: rgba(34, 197, 94, 0.1); color: #16A34A;'
    when 'draft'
      'background: rgba(245, 158, 11, 0.1); color: #D97706;'
    when 'archived'
      'background: rgba(148, 163, 184, 0.1); color: #64748B;'
    else
      'background: var(--gray-100); color: var(--gray-700);'
    end
  end

  def interaction_type_label(interaction_type)
    {
      'call' => 'Звонок',
      'meeting' => 'Встреча',
      'email' => 'Email',
      'chat' => 'Чат',
      'note' => 'Заметка'
    }[interaction_type.to_s] || interaction_type
  end

  def interaction_type_badge_style(interaction_type)
    case interaction_type.to_s
    when 'call'
      'background: rgba(14, 165, 233, 0.1); color: #0ea5e9;'
    when 'meeting'
      'background: rgba(168, 85, 247, 0.1); color: #9333EA;'
    when 'email'
      'background: rgba(34, 197, 94, 0.1); color: #16A34A;'
    when 'chat'
      'background: rgba(245, 158, 11, 0.1); color: #D97706;'
    when 'note'
      'background: rgba(148, 163, 184, 0.1); color: #64748B;'
    else
      'background: rgba(148, 163, 184, 0.1); color: #64748B;'
    end
  end

  def interaction_status_label(status)
    {
      'planned' => 'Запланировано',
      'completed' => 'Завершено',
      'cancelled' => 'Отменено'
    }[status.to_s] || status
  end

  def interaction_status_badge_style(status)
    case status.to_s
    when 'planned'
      'background: rgba(245, 158, 11, 0.1); color: #D97706;'
    when 'completed'
      'background: rgba(34, 197, 94, 0.1); color: #16A34A;'
    when 'cancelled'
      'background: rgba(239, 68, 68, 0.1); color: #DC2626;'
    else
      'background: rgba(148, 163, 184, 0.1); color: #64748B;'
    end
  end

  # Integration helpers
  def integration_type_label(integration_type)
    {
      'email' => 'Email (SMTP)',
      'telegram' => 'Telegram Bot',
      'google_analytics' => 'Google Analytics',
      'cloudpayments' => 'CloudPayments'
    }[integration_type.to_s] || integration_type
  end

  # Category icon SVG paths
  def category_icon_svg(slug)
    case slug
    when 'videokursy', 'video-kursy', 'courses'
      '<path d="m22 8-6 4 6 4V8Z"></path><rect width="14" height="12" x="2" y="6" rx="2" ry="2"></rect>'.html_safe
    when 'knigi', 'books'
      '<path d="M2 3h6a4 4 0 0 1 4 4v14a3 3 0 0 0-3-3H2z"></path><path d="M22 3h-6a4 4 0 0 0-4 4v14a3 3 0 0 1 3-3h7z"></path>'.html_safe
    when 'kursy'
      '<path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"></path><path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"></path>'.html_safe
    when 'meropriyatiya', 'events'
      '<rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect><line x1="16" y1="2" x2="16" y2="6"></line><line x1="8" y1="2" x2="8" y2="6"></line><line x1="3" y1="10" x2="21" y2="10"></line>'.html_safe
    else
      '<path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"></path><polyline points="3.27 6.96 12 12.01 20.73 6.96"></polyline><line x1="12" y1="22.08" x2="12" y2="12"></line>'.html_safe
    end
  end
end
