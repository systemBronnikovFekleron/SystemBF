# frozen_string_literal: true

module Admin
  class IntegrationsController < BaseController
    before_action :set_integration, only: [:show, :edit, :update, :test_connection, :toggle_status, :logs, :statistics]

    def index
      authorize IntegrationSetting
      @integrations = policy_scope(IntegrationSetting).order(:integration_type)
      @statistics_summary = calculate_statistics_summary
    end

    def show
      authorize @integration
      @recent_logs = @integration.integration_logs.recent.limit(10)
      @daily_stats = @integration.integration_statistics.daily.recent(30)
    end

    def edit
      authorize @integration
    end

    def update
      authorize @integration

      if params[:integration_setting][:credentials].present?
        # Обновляем credentials отдельно через encrypted метод
        credentials = credentials_params
        @integration.update_credentials!(credentials)
      end

      # Обновляем остальные поля
      @integration.updated_by = current_user

      if @integration.update(integration_params)
        redirect_to admin_integration_path(@integration),
                    notice: 'Настройки интеграции успешно обновлены.'
      else
        flash.now[:alert] = 'Ошибка при обновлении настроек.'
        render :edit, status: :unprocessable_entity
      end
    end

    def test_connection
      authorize @integration, :test_connection?

      result = @integration.test_connection

      if result[:success]
        redirect_to admin_integration_path(@integration),
                    notice: result[:message]
      else
        redirect_to admin_integration_path(@integration),
                    alert: result[:message]
      end
    end

    def toggle_status
      authorize @integration, :toggle_status?

      if @integration.enabled?
        @integration.disable!
        message = 'Интеграция отключена.'
      else
        @integration.enable!
        message = 'Интеграция включена.'
      end

      redirect_to admin_integration_path(@integration), notice: message
    end

    def logs
      authorize @integration, :logs?
      @logs = @integration.integration_logs
                          .includes(:related)
                          .order(created_at: :desc)
                          .page(params[:page])
                          .per(50)

      @filter_status = params[:status]
      @logs = @logs.where(status: @filter_status) if @filter_status.present?

      @filter_event_type = params[:event_type]
      @logs = @logs.where(event_type: @filter_event_type) if @filter_event_type.present?
    end

    def statistics
      authorize @integration, :statistics?
      @period = params[:period] || 'daily'

      @statistics = case @period
                    when 'daily'
                      @integration.integration_statistics.daily.recent(30)
                    when 'weekly'
                      @integration.integration_statistics.weekly.recent(12)
                    when 'monthly'
                      @integration.integration_statistics.monthly.recent(12)
                    else
                      @integration.integration_statistics.daily.recent(30)
                    end

      @chart_data = prepare_chart_data(@statistics)
    end

    private

    def set_integration
      @integration = IntegrationSetting.find(params[:id])
    end

    def integration_params
      params.require(:integration_setting).permit(
        :name,
        :description,
        :enabled,
        settings: {}
      )
    end

    def credentials_params
      creds = params.require(:integration_setting).require(:credentials)
      creds.permit!.to_h
    end

    def calculate_statistics_summary
      {
        total_integrations: IntegrationSetting.count,
        enabled_integrations: IntegrationSetting.enabled.count,
        healthy_integrations: IntegrationSetting.healthy.count,
        total_logs_today: IntegrationLog.today.count
      }
    end

    def prepare_chart_data(statistics)
      {
        labels: statistics.map { |s| s.date.strftime('%d.%m') },
        total: statistics.map(&:total_requests),
        successful: statistics.map(&:successful_requests),
        failed: statistics.map(&:failed_requests),
        success_rate: statistics.map(&:success_rate_percentage)
      }
    end
  end
end
