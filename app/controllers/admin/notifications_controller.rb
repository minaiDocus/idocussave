# frozen_string_literal: true

class Admin::NotificationsController < Admin::AdminController
  def index
    @notifications = Notification.search(search_terms(params[:notification_contains])).order(sort_column => sort_direction).page(params[:page]).per(params[:per_page])
  end

  private

  def sort_column
    params[:sort] || 'created_at'
  end
  helper_method :sort_column

  def sort_direction
    params[:direction] || 'desc'
  end
  helper_method :sort_direction
end
