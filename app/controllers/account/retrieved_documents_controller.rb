# -*- encoding : UTF-8 -*-
class Account::RetrievedDocumentsController < Account::RetrieverController
  before_filter :load_document, only: %w(show piece)

  def index
    @documents = TempDocument.search_for_collection(@user.temp_documents.retrieved, search_terms(params[:document_contains])).includes(:retriever).includes(:piece).order(sort_column => sort_direction)
    @documents_count = @documents.count
    @documents = @documents.page(params[:page]).per(params[:per_page])
    @is_filter_empty = search_terms(params[:document_contains]).empty?
  end

  def show
    filepath = FileStoragePathUtils.path_for_object(@document)

    if File.exist?(filepath)
      file_name = @document.metadata['libelle'] + '.pdf'

      send_file(filepath, type: 'application/pdf', filename: file_name, x_sendfile: true, disposition: 'inline')
    else
      render nothing: true, status: 404
    end
  end

  def piece
    if @document.piece
      filepath = FileStoragePathUtils.path_for_object(@document.piece)
      if File.exist?(filepath)
        send_file(filepath, type: 'application/pdf', filename: @document.piece.content_file_name, x_sendfile: true, disposition: 'inline')
      else
        render nothing: true, status: 404
      end
    else
      render nothing: true, status: 404
    end
  end

  def select
    @documents = TempDocument.search_for_collection(@user.temp_documents.retrieved, search_terms(params[:document_contains])).wait_selection.includes(:retriever).includes(:piece).order(sort_column => sort_direction).page(params[:page]).per(params[:per_page])
    @retriever.ready if @retriever && @retriever.waiting_selection?
    @is_filter_empty = search_terms(params[:document_contains]).empty?
  end

  def validate
    documents = @user.temp_documents.find(params[:document_ids] || [])
    if documents.count == 0
      flash[:notice] = 'Aucun document sélectionné.'
    else
      documents.each do |document|
        document.ready if document.wait_selection?
      end
      if documents.count > 1
        flash[:success] = "Les #{documents.count} documents sélectionnés seront intégrés."
      else
        flash[:success] = 'Le document sélectionné sera intégré.'
      end
    end
    redirect_to select_account_retrieved_documents_path(document_contains: search_terms(params[:document_contains]))
  end

  private

  def load_document
    @document = @user.temp_documents.retrieved.find(params[:id])
  end

  def sort_column
    params[:sort] || 'created_at'
  end
  helper_method :sort_column

  def sort_direction
    params[:direction] || 'desc'
  end
  helper_method :sort_direction
end
