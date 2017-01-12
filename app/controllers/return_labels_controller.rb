# -*- encoding : UTF-8 -*-
class ReturnLabelsController < ApplicationController
  before_filter :authenticate


  # GET /scans/return_labels
  def show
    filepath = ReturnLabels::FILE_PATH

    if File.exist?(filepath)
      filename = File.basename(filepath)

      send_file(filepath, type: 'application/pdf', filename: filename, x_sendfile: true, disposition: 'inline')
    else
      render nothing: true, status: 404
    end
  end


  # GET /scans/return_labels/new
  def new
    #@scanned_by = @user.scanning_provider.name if @user || nil 'ppp'
    @scanned_by = 'ppp'

    @return_labels = ReturnLabels.new(scanned_by: @scanned_by, time: @current_time)

    @customers = @return_labels.users.sort_by do |e|
      (e.is_return_label_generated_today? ? '1_' : '0_') + e.code
    end
  end

  
  # POST /scans/return_labels
  def create
    if params[:return_labels] && params[:return_labels][:customers]
      @return_labels = ReturnLabels.new(params[:return_labels].merge(time: @current_time))
      @return_labels.render_pdf
    end
    redirect_to '/scans/return_labels'
  end

  private


  def authenticate
    unless current_user && current_user.is_admin
      authenticate_or_request_with_http_basic do |name, password|
        operators = [{"username":"ppp","password":"QIuVMP5dwMExgrYqClLc","scanning_provider":"ppp","is_return_labels_authorized":true}]
        @user = operators.select do |operator|
          'ppp' == name && 'QIuVMP5dwMExgrYqClLc' == password
        end.first
        @user.present?
      end
    end
  end
end
