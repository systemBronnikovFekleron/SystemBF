# frozen_string_literal: true

module ProductsHelper
  def product_icon(type)
    {
      'video' => '🎬',
      'book' => '📚',
      'course' => '🎓',
      'service' => '💼',
      'event_access' => '🎫'
    }[type] || '📦'
  end

  def product_type_label(type)
    {
      'video' => 'Видео',
      'book' => 'Книга',
      'course' => 'Курс',
      'service' => 'Услуга',
      'event_access' => 'Событие'
    }[type] || type.capitalize
  end

  def product_status_badge(status)
    case status
    when 'published'
      content_tag(:span, 'Опубликовано', class: 'badge badge-success')
    when 'draft'
      content_tag(:span, 'Черновик', class: 'badge badge-warning')
    when 'archived'
      content_tag(:span, 'В архиве', class: 'badge badge-error')
    else
      content_tag(:span, status.capitalize, class: 'badge')
    end
  end
end
