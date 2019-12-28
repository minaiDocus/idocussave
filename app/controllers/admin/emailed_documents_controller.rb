# frozen_string_literal: true

class Admin::EmailedDocumentsController < Admin::AdminController
  # GET /admin/emailed_documents
  def index
    @emails = Email.search(search_terms(params[:emailed_document_contains])).order(sort_column => sort_direction).includes(:to_user, :from_user)

    @emails_count = @emails.count

    @emails = @emails.page(params[:page]).per(params[:per_page])
  end

  # GEt /admin/emailed_documents/:id
  def show
    @email = Email.find(params[:id])

    file_path = @email.cloud_original_content_object.path

    if file_path.present? && File.exist?(file_path)
      file_name = File.basename(file_path)

      send_file(file_path, type: 'message/rfc822', filename: file_name, x_sendfile: true)
    else
      raise ActionController::RoutingError, 'Not Found'
    end
  end

  # GET /admin/emailed_documents/:id/show_errors
  def show_errors
    @email = Email.find(params[:id])
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
