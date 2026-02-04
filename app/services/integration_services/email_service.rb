# frozen_string_literal: true

require 'net/smtp'

module IntegrationServices
  class EmailService < BaseService
    class << self
      def test_connection(credentials, settings = {})
        smtp_address = credentials['smtp_address'] || credentials[:smtp_address]
        smtp_port = (credentials['smtp_port'] || credentials[:smtp_port] || 587).to_i
        smtp_user = credentials['smtp_user_name'] || credentials[:smtp_user_name]
        smtp_password = credentials['smtp_password'] || credentials[:smtp_password]

        return missing_credentials_error unless smtp_address && smtp_user && smtp_password

        begin
          smtp = Net::SMTP.new(smtp_address, smtp_port)
          smtp.enable_starttls_auto if credentials['smtp_enable_starttls_auto'] != 'false'

          smtp.start(credentials['smtp_domain'] || 'localhost', smtp_user, smtp_password,
                     (credentials['smtp_authentication'] || 'plain').to_sym) do |smtp_connection|
            # Успешное подключение
            true
          end

          {
            success: true,
            message: "SMTP подключение успешно (#{smtp_address}:#{smtp_port})"
          }
        rescue Net::SMTPAuthenticationError => e
          {
            success: false,
            message: "Ошибка аутентификации SMTP: #{e.message}"
          }
        rescue SocketError => e
          {
            success: false,
            message: "Не удается подключиться к SMTP серверу: #{e.message}"
          }
        rescue StandardError => e
          {
            success: false,
            message: "Ошибка SMTP: #{e.message}"
          }
        end
      end

      # Send email using integration settings
      def send_email(to:, subject:, body_html:, body_text: nil, template: nil)
        return false unless enabled?

        with_logging('email_sent', metadata: { to: to, subject: subject }) do
          configure_action_mailer!

          if template.is_a?(EmailTemplate)
            # Use EmailTemplate
            ApplicationMailer.with(
              to: to,
              subject: template.render_subject,
              body_html: template.render_body_html,
              body_text: template.render_body_text
            ).generic_email.deliver_later

            template.increment_sent!
          else
            # Use direct parameters
            ApplicationMailer.with(
              to: to,
              subject: subject,
              body_html: body_html,
              body_text: body_text
            ).generic_email.deliver_later
          end

          true
        end
      end

      # Configure ActionMailer with integration settings
      def configure_action_mailer!
        return unless enabled?

        creds = credentials
        sett = settings

        ActionMailer::Base.smtp_settings = {
          address: creds['smtp_address'],
          port: creds['smtp_port']&.to_i || 587,
          domain: creds['smtp_domain'] || 'localhost',
          user_name: creds['smtp_user_name'],
          password: creds['smtp_password'],
          authentication: creds['smtp_authentication']&.to_sym || :plain,
          enable_starttls_auto: creds['smtp_enable_starttls_auto'] != 'false'
        }

        ActionMailer::Base.default_options = {
          from: sett['from_email'] || 'noreply@example.com',
          reply_to: sett['reply_to_email'] || sett['from_email']
        }
      end

      private

      def integration_type_key
        'email'
      end

      def rails_credentials_fallback
        smtp_config = Rails.application.credentials.dig(:smtp) || {}
        {
          smtp_address: smtp_config[:address],
          smtp_port: smtp_config[:port],
          smtp_domain: smtp_config[:domain],
          smtp_user_name: smtp_config[:user_name],
          smtp_password: smtp_config[:password],
          smtp_authentication: smtp_config[:authentication],
          smtp_enable_starttls_auto: smtp_config[:enable_starttls_auto]
        }.compact
      end

      def missing_credentials_error
        {
          success: false,
          message: 'Отсутствуют обязательные параметры: smtp_address, smtp_user_name, smtp_password'
        }
      end
    end
  end
end
