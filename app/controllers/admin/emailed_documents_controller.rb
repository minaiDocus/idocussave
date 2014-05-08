# -*- encoding : UTF-8 -*-
class Admin::EmailedDocumentsController < Admin::AdminController

  def index
    @emails = search(emailed_document_contains).order([sort_column, sort_direction]).page(params[:page]).per(params[:per_page])
  end

  def show
    @email = Email.find params[:id]
    file_path = @email.original_content.path
    if file_path.present? && File.exist?(file_path)
      file_name = File.basename file_path
      send_file(file_path, type: 'message/rfc822', filename: file_name, x_sendfile: true)
    else
      raise ActionController::RoutingError.new('Not Found')
    end
  end

  def show_errors
    @email = Email.find params[:id]
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

  def emailed_document_contains
    @contains ||= {}
    if params[:emailed_document_contains] && @contains.blank?
      @contains = params[:emailed_document_contains].delete_if do |_,value|
        if value.blank? && !value.is_a?(Hash)
          true
        elsif value.is_a? Hash
          value.delete_if { |k,v| v.blank? }
          value.blank?
        else
          false
        end
      end
    end
    @contains
  end
  helper_method :emailed_document_contains

  def search(contains)
    user_ids = []
    if params[:user_contains] && params[:user_contains][:code].present?
      user_ids = User.where(code: /#{Regexp.quote(params[:user_contains][:code])}/i).distinct(:_id)
    end
    emailed_documents = Email.all
    emailed_documents = emailed_documents.any_of({ :to_user_id.in => user_ids }, { :from_user_id.in => user_ids }) if user_ids.any?
    emailed_documents = emailed_documents.where(created_at: contains[:created_at])                  unless contains[:created_at].blank?
    emailed_documents = emailed_documents.where(state:      contains[:state])                       unless contains[:state].blank?
    emailed_documents = emailed_documents.where(from:       /#{Regexp.quote(contains[:from])}/i)    unless contains[:from].blank?
    emailed_documents = emailed_documents.where(to:         /#{Regexp.quote(contains[:to])}/i)      unless contains[:to].blank?
    emailed_documents = emailed_documents.where(subject:    /#{Regexp.quote(contains[:subject])}/i) unless contains[:subject].blank?
    emailed_documents
  end
end
