# -*- encoding : UTF-8 -*-
class PaperProcessesController < ApplicationController
  layout 'paper_process'

  before_filter :authenticate
  before_filter :load_current_time

private

  def authenticate
    unless current_user && current_user.is_admin
      authenticate_or_request_with_http_basic do |name, password|
        @user = Num::USERS.select { |u| u[0] == name && u[1] == password }.first
        @user.present?
      end
    end
  end

  def load_current_time
    if params[:year] && params[:month] && params[:day]
      begin
        @current_time = Time.local(params[:year], params[:month], params[:day])
      rescue ArgumentError
        @current_time = Time.now
      end
    else
      @current_time = Time.now
    end
  end
end
