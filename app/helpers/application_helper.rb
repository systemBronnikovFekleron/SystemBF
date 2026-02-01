# frozen_string_literal: true

module ApplicationHelper
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
end
