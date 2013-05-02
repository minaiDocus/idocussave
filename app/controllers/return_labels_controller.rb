# -*- encoding : UTF-8 -*-
class ReturnLabelsController < ApplicationController
  before_filter :authenticate

  def show
    filepath = ReturnLabels::FILE_PATH
    if File.exist?(filepath)
      filename = File.basename(filepath)
      send_file(filepath, type: 'application/pdf', filename: filename, x_sendfile: true, disposition: 'inline')
    else
      render nothing: true, status: 404
    end
  end

  def new
    @scanned_by = @user.try(:[], 2) || '.*'
    @return_labels = ReturnLabels.new(scanned_by: @scanned_by)
    @customers = @return_labels.users.sort_by do |e|
      (e.is_return_label_generated_today? ? '1_' : '0_') + e.code
    end
  end

  def create
    if params[:return_labels] && params[:return_labels][:customers]
      @return_labels = ReturnLabels.new(params[:return_labels])
      @return_labels.render_pdf
    end
    redirect_to '/num/return_labels'
  end

private

  def authenticate
    unless current_user && current_user.is_admin
      authenticate_or_request_with_http_basic do |name, password|
        @user = Num::USERS.select { |u| u[0] == name && u[1] == password && u[3] == true }.first
        @user.present?
      end
    end
  end
end