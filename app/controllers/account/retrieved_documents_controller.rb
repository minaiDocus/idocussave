# -*- encoding : UTF-8 -*-
class Account::RetrievedDocumentsController < Account::FiduceoController
  layout 'layouts/account/retrievers'
  before_filter :load_retriever_ids
  before_filter :load_document, only: %w(show piece)

  def index
    @documents = search(document_contains).order([sort_column,sort_direction]).page(params[:page]).per(params[:per_page])
    @is_filter_empty = document_contains.empty?
  end

  def show
    if File.exist?(@document.content.path)
      file_name = @document.fiduceo_metadata['libelle'] + '.pdf'
      send_file(@document.content.path, type: 'application/pdf', filename: file_name, x_sendfile: true, disposition: 'inline')
    else
      render nothing: true, status: 404
    end
  end

  def piece
    if @document.piece && File.exist?(@document.piece.content.path)
      send_file(@document.piece.content.path, type: 'application/pdf', filename: @document.piece.content_file_name, x_sendfile: true, disposition: 'inline')
    else
      render nothing: true, status: 404
    end
  end

  def select
    @documents = search(document_contains).order([sort_column,sort_direction]).wait_selection.page(params[:page]).per(params[:per_page])
    @retriever.schedule if @retriever && @retriever.wait_selection?
    @is_filter_empty = document_contains.empty?
  end

  def validate
    documents = @user.temp_documents.find(params[:document_ids] || [])
    if documents.count == 0
      flash[:notice] = 'Aucun document sélectionné.'
    else
      documents.each do |document|
        document.ready
      end
      if documents.count > 1
        flash[:success] = "Les #{documents.count} documents sélectionnés seront intégrés."
      else
        flash[:success] = 'Le document sélectionné sera intégré.'
      end
    end
    redirect_to select_account_retrieved_documents_path(document_contains: document_contains)
  end

private

  def load_retriever_ids
    @retriever_ids = @user.fiduceo_retrievers.distinct(:_id)
  end

  def load_document
    @document = TempDocument.fiduceo.where(:fiduceo_retriever_id.in => @retriever_ids).find(params[:id])
  end

  def sort_column
    params[:sort] || 'created_at'
  end
  helper_method :sort_column

  def sort_direction
    params[:direction] || 'desc'
  end
  helper_method :sort_direction

  def document_contains
    @contains ||= {}
    if params[:document_contains] && @contains.blank?
      @contains = params[:document_contains].delete_if do |_,value|
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
  helper_method :document_contains

  def search(contains)
    documents = @user.temp_documents.fiduceo.includes(:fiduceo_retriever)
    documents = documents.where('fiduceo_metadata.libelle' => /#{Regexp.quote(contains[:name])}/i) unless contains[:name].blank?
    if contains[:service_name]
      documents = documents.where(fiduceo_service_name: /#{Regexp.quote(contains[:service_name])}/i)
    elsif contains[:retriever_id]
      @retriever = @user.fiduceo_retrievers.find(contains[:retriever_id])
      documents = documents.where(:fiduceo_retriever_id => @retriever.id)
    end
    if contains[:transaction_id]
      @transaction = @user.fiduceo_transactions.find(contains[:transaction_id])
      documents = documents.where(:fiduceo_id.in => @transaction.retrieved_document_ids)
    end
    if contains[:date].present?
      begin
        contains[:date]['$gte'] = Time.zone.parse(contains[:date]['$gte']).to_time if contains[:date]['$gte']
        contains[:date]['$lte'] = Time.zone.parse(contains[:date]['$lte']).to_time if contains[:date]['$lte']
        documents = documents.where('fiduceo_metadata.date' => contains[:date])
      rescue ArgumentError
        documents = []
      end
    end
    documents
  end
end
