# -*- encoding : UTF-8 -*-
class Account::Organization::IbizaboxDocumentsController < Account::OrganizationController
  before_filter :load_customer
  before_filter :load_document, except: %w(index select validate)

  def index
    collection = @customer.temp_documents.from_ibizabox.joins([ibizabox_folder: :journal]).select("temp_documents.*, account_book_types.name as journal")
    @documents = TempDocument.search_ibizabox_collection(collection, search_terms(params[:document_contains])).includes(:retriever).includes(:piece).order("#{sort_column} #{sort_direction}")
    @documents_count = @documents.size
    @documents = @documents.page(params[:page]).per(params[:per_page])
  end

  def show
    filepath = FileStoragePathUtils.path_for_object(@document)

    if File.exist?(filepath)
      file_name = @document.original_file_name

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
    collection = @customer.temp_documents.wait_selection.from_ibizabox.joins([ibizabox_folder: :journal]).where("ibizabox_folders.state in ('waiting_selection','ready')").select("temp_documents.*, account_book_types.name as journal")
    @documents = TempDocument.search_ibizabox_collection(collection, search_terms(params[:document_contains])).includes(:piece).order("#{sort_column} #{sort_direction}").page(params[:page]).per(params[:per_page])
  end

  def validate
    documents = @customer.temp_documents.wait_selection.from_ibizabox.find(params[:document_ids] || [])
    if documents.count == 0
      flash[:notice] = 'Aucun document sélectionné.'
    else
      documents.map(&:ibizabox_folder).compact.uniq.each do |ibizabox_folder|
        ibizabox_folder.ready if ibizabox_folder.waiting_selection?
      end
      documents.each do |document|
        if DocumentTools.need_ocr?(document.content.path)
          document.ocr_needed
        else
          document.ready
        end
      end
      if documents.count > 1
        flash[:success] = "Les #{documents.count} documents sélectionnés seront intégrés."
      else
        flash[:success] = 'Le document sélectionné sera intégré.'
      end
    end
    redirect_to select_account_organization_customer_ibizabox_documents_path(@organization, @customer, document_contains: params[:document_contains])
  end

private

  def load_document
    @document = @customer.temp_documents.from_ibizabox.find(params[:id])
  end

  def sort_column
    if params[:sort].in? %w(created_at journal original_file_name pages_number)
      params[:sort]
    else
      'created_at'
    end
  end
  helper_method :sort_column

  def sort_direction
    if params[:direction].in? %w(asc desc)
      params[:direction]
    else
      'desc'
    end
  end
  helper_method :sort_direction
end
