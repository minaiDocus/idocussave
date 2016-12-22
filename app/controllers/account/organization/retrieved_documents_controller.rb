# -*- encoding : UTF-8 -*-
class Account::Organization::RetrievedDocumentsController < Account::Organization::FiduceoController
  before_filter :load_document, except: %w(index select validate)

  def index
    @documents = TempDocument.search_for_collection(@customer.temp_documents.fiduceo, search_terms(params[:document_contains])).includes(:fiduceo_retriever).order(sort_column => sort_direction).includes(:piece)

    @documents_count = @documents.count

    @documents = @documents.page(params[:page]).per(params[:per_page])
  end


  # FIXME : check if needed
  def show
    if File.exist?(@document.content.path)
      file_name = @document.fiduceo_metadata['libelle'] + '.pdf'

      file_path = FileStoragePathUtils.path_for_object(@document)

      send_file(filepath, type: 'application/pdf', filename: file_name, x_sendfile: true, disposition: 'inline')
    end
  end


  # GET /account/organizations/:organization_id/customers/:customer_id/retrieved_documents/:id/piece
  def piece
    if @document.piece && File.exist?(@document.piece.content.path)
      send_file(@document.piece.content.path, type: 'application/pdf', filename: @document.piece.content_file_name, x_sendfile: true, disposition: 'inline')
    end
  end


  # GET /account/organizations/:organization_id/customers/:customer_id/retrieved_documents/select
  def select
    @documents = TempDocument.search_for_collection(@customer.temp_documents.fiduceo, search_terms(params[:document_contains])).order(sort_column => sort_direction).wait_selection.page(params[:page]).per(params[:per_page])

    @retriever.schedule if @retriever && @retriever.wait_selection?
  end


  # PUT /account/organizations/:organization_id/customers/:customer_id/retrieved_documents/validate
  def validate
    documents = @customer.temp_documents.find(params[:document_ids] || [])

    if documents.count == 0
      flash[:notice] = 'Aucun document sélectionné.'
    else
      documents.each(&:ready)

      if documents.count > 1
        flash[:success] = "Les #{documents.count} documents sélectionnés seront intégrés."
      else
        flash[:success] = 'Le document sélectionné sera intégré.'
      end
    end

    redirect_to select_account_organization_customer_retrieved_documents_path(@organization, @customer, document_contains: document_contains)
  end


  private

  def load_document
    @document = @customer.temp_documents.fiduceo.find(params[:id])
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
