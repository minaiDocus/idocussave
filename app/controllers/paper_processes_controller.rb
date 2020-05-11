# frozen_string_literal: true

class PaperProcessesController < ApplicationController
  layout 'paper_process'

  before_action :authenticate
  before_action :load_current_time

  private

  def authenticate
    unless current_user&.is_admin
      authenticate_or_request_with_http_basic do |name, password|
        operators = [{ "username": 'ppp', "password": 'QIuVMP5dwMExgrYqClLc', "scanning_provider": 'ppp', "is_return_labels_authorized": true }]
        @user = operators.select do |_operator|
          name == 'ppp' && password == 'QIuVMP5dwMExgrYqClLc'
        end.first
        @user.present?
      end
    end
  end

  def load_current_time
    if params[:year] && params[:month] && params[:day]
      begin
        @current_time = Time.local(params[:year], params[:month], params[:day])
      rescue ArgumentError
      end
    end
    @current_time ||= Time.now
  end
end
