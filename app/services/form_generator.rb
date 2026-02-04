# frozen_string_literal: true

class FormGenerator
  def self.generate_html(product, action_url)
    new(product, action_url).generate
  end

  def initialize(product, action_url)
    @product = product
    @action_url = action_url
  end

  def generate
    <<~HTML
      <!DOCTYPE html>
      <html lang="ru">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>#{@product.name} - Заявка</title>
        <style>
          * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
          }

          body {
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
          }

          .form-container {
            background: rgba(255, 255, 255, 0.95);
            backdrop-filter: blur(10px);
            border-radius: 20px;
            padding: 40px;
            max-width: 500px;
            width: 100%;
            box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
          }

          h1 {
            color: #2d3748;
            margin-bottom: 10px;
            font-size: 28px;
            text-align: center;
          }

          .subtitle {
            color: #718096;
            text-align: center;
            margin-bottom: 30px;
            font-size: 14px;
          }

          .form-group {
            margin-bottom: 20px;
          }

          label {
            display: block;
            margin-bottom: 8px;
            color: #4a5568;
            font-weight: 500;
            font-size: 14px;
          }

          input[type="text"],
          input[type="email"],
          input[type="tel"],
          textarea,
          select {
            width: 100%;
            padding: 12px 16px;
            border: 2px solid #e2e8f0;
            border-radius: 10px;
            font-size: 15px;
            transition: all 0.3s ease;
            font-family: inherit;
          }

          input:focus,
          textarea:focus,
          select:focus {
            outline: none;
            border-color: #667eea;
            box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
          }

          textarea {
            min-height: 100px;
            resize: vertical;
          }

          button {
            width: 100%;
            padding: 14px 24px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border: none;
            border-radius: 10px;
            font-size: 16px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s ease;
            margin-top: 10px;
          }

          button:hover {
            transform: translateY(-2px);
            box-shadow: 0 10px 30px rgba(102, 126, 234, 0.4);
          }

          button:active {
            transform: translateY(0);
          }

          .message {
            padding: 16px;
            border-radius: 10px;
            margin-bottom: 20px;
            display: none;
            animation: slideDown 0.3s ease;
          }

          @keyframes slideDown {
            from {
              opacity: 0;
              transform: translateY(-10px);
            }
            to {
              opacity: 1;
              transform: translateY(0);
            }
          }

          .message.success {
            background: #c6f6d5;
            color: #22543d;
            border: 2px solid #9ae6b4;
            display: block;
          }

          .message.error {
            background: #fed7d7;
            color: #742a2a;
            border: 2px solid #fc8181;
            display: block;
          }

          .loading {
            pointer-events: none;
            opacity: 0.6;
          }

          .required {
            color: #e53e3e;
          }
        </style>
      </head>
      <body>
        <div class="form-container">
          <h1>#{@product.name}</h1>
          <p class="subtitle">Заполните форму для оформления заявки</p>

          <div id="message" class="message"></div>

          <form id="orderForm">
            <input type="hidden" name="product_id" value="#{@product.id}">

            <div class="form-group">
              <label for="email">Email <span class="required">*</span></label>
              <input type="email" id="email" name="email" required>
            </div>

            <div class="form-group">
              <label for="first_name">Имя</label>
              <input type="text" id="first_name" name="first_name">
            </div>

            <div class="form-group">
              <label for="last_name">Фамилия</label>
              <input type="text" id="last_name" name="last_name">
            </div>

            <div class="form-group">
              <label for="phone">Телефон</label>
              <input type="tel" id="phone" name="phone">
            </div>

            #{custom_fields_html}

            <button type="submit">Отправить заявку</button>
          </form>
        </div>

        <script>
          document.getElementById('orderForm').addEventListener('submit', async function(e) {
            e.preventDefault();

            const form = e.target;
            const submitBtn = form.querySelector('button[type="submit"]');
            const messageEl = document.getElementById('message');

            submitBtn.classList.add('loading');
            submitBtn.textContent = 'Отправка...';
            messageEl.style.display = 'none';

            const formData = new FormData(form);
            const data = Object.fromEntries(formData.entries());

            try {
              const response = await fetch('#{@action_url}', {
                method: 'POST',
                headers: {
                  'Content-Type': 'application/json',
                },
                body: JSON.stringify(data)
              });

              const result = await response.json();

              if (result.success) {
                messageEl.className = 'message success';
                messageEl.textContent = '✓ Заявка успешно создана! Номер заявки: ' + result.request_number;
                form.reset();
              } else {
                messageEl.className = 'message error';
                messageEl.textContent = '✗ Ошибка: ' + result.error;
              }
            } catch (error) {
              messageEl.className = 'message error';
              messageEl.textContent = '✗ Ошибка подключения. Попробуйте позже.';
            } finally {
              submitBtn.classList.remove('loading');
              submitBtn.textContent = 'Отправить заявку';
            }
          });
        </script>
      </body>
      </html>
    HTML
  end

  private

  def custom_fields_html
    return '' if @product.form_fields.blank?

    @product.form_fields.map do |field|
      case field['field_type']
      when 'text'
        text_field_html(field)
      when 'textarea'
        textarea_field_html(field)
      when 'select'
        select_field_html(field)
      when 'checkbox'
        checkbox_field_html(field)
      else
        ''
      end
    end.join("\n")
  end

  def text_field_html(field)
    required = field['required'] ? 'required' : ''
    required_mark = field['required'] ? '<span class="required">*</span>' : ''

    <<~HTML
      <div class="form-group">
        <label for="#{field['name']}">#{field['label']} #{required_mark}</label>
        <input type="text" id="#{field['name']}" name="#{field['name']}" #{required}>
      </div>
    HTML
  end

  def textarea_field_html(field)
    required = field['required'] ? 'required' : ''
    required_mark = field['required'] ? '<span class="required">*</span>' : ''

    <<~HTML
      <div class="form-group">
        <label for="#{field['name']}">#{field['label']} #{required_mark}</label>
        <textarea id="#{field['name']}" name="#{field['name']}" #{required}></textarea>
      </div>
    HTML
  end

  def select_field_html(field)
    required = field['required'] ? 'required' : ''
    required_mark = field['required'] ? '<span class="required">*</span>' : ''
    options = field['options'] || []

    options_html = options.map { |opt| "<option value=\"#{opt}\">#{opt}</option>" }.join("\n")

    <<~HTML
      <div class="form-group">
        <label for="#{field['name']}">#{field['label']} #{required_mark}</label>
        <select id="#{field['name']}" name="#{field['name']}" #{required}>
          <option value="">Выберите...</option>
          #{options_html}
        </select>
      </div>
    HTML
  end

  def checkbox_field_html(field)
    required = field['required'] ? 'required' : ''

    <<~HTML
      <div class="form-group">
        <label>
          <input type="checkbox" id="#{field['name']}" name="#{field['name']}" value="true" #{required}>
          #{field['label']}
        </label>
      </div>
    HTML
  end
end
