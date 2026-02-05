# frozen_string_literal: true

module Admin
  class NotificationsController < Admin::BaseController
    def index
      @notifications = Notification.includes(:user)
                                   .recent
                                   .page(params[:page]).per(50)

      # Фильтры
      @notifications = @notifications.where(notification_type: params[:type]) if params[:type].present?
      @notifications = @notifications.where(read: params[:read]) if params[:read].present?
    end

    def new
      @notification = Notification.new
      @users = User.order(:email)
    end

    def create
      if params[:broadcast] == 'true'
        # Broadcast to all users
        broadcast_notification
      else
        # Single user notification
        create_single_notification
      end
    end

    def destroy
      @notification = Notification.find(params[:id])
      @notification.destroy
      redirect_to admin_notifications_path, notice: 'Уведомление удалено'
    end

    def bulk_destroy
      notification_ids = params[:notification_ids] || []
      Notification.where(id: notification_ids).destroy_all
      redirect_to admin_notifications_path, notice: "#{notification_ids.count} уведомлений удалено"
    end

    private

    def broadcast_notification
      title = notification_params[:title]
      message = notification_params[:message]
      action_url = notification_params[:action_url]
      action_text = notification_params[:action_text]

      count = 0
      User.find_each do |user|
        NotificationService.system_notification(user, title, message, action_url: action_url, action_text: action_text)
        count += 1
      end

      redirect_to admin_notifications_path, notice: "Уведомление отправлено #{count} пользователям"
    end

    def create_single_notification
      @notification = Notification.new(notification_params)

      if @notification.save
        redirect_to admin_notifications_path, notice: 'Уведомление создано'
      else
        @users = User.order(:email)
        render :new, status: :unprocessable_entity
      end
    end

    def notification_params
      params.require(:notification).permit(
        :user_id, :notification_type, :title, :message,
        :action_url, :action_text
      )
    end
  end
end
