# -*- encoding : UTF-8 -*-
class PaperProcessesController < ApplicationController
  layout 'paper_process'

  before_filter :authenticate

  private

  def authenticate
    unless current_user && current_user.is_admin
      authenticate_or_request_with_http_basic do |name, password|
        operators = [{"username":"ppp","password":"QIuVMP5dwMExgrYqClLc", "is_return_labels_authorized":true}]
        @user = operators.select do |operator|
          'ppp' == name && 'QIuVMP5dwMExgrYqClLc' == password
        end.first
        @user.present?
      end
    end
  end
end
