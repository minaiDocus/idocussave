# -*- encoding : UTF-8 -*-
class Account::Organization::RetrievedDocumentsController < Account::Organization::FiduceoController
  before_filter :load_document, except: %w(index select validate)

  def index
    @documents = search(document_contains).order_by(sort_column => sort_direction).page(params[:page]).per(params[:per_page])
  end

  def show
    if File.exist?(@document.content.path)
      file_name = @document.fiduceo_metadata['libelle'] + '.pdf'
      send_file(@document.content.path, type: 'application/pdf', filename: file_name, x_sendfile: true, disposition: 'inline')
    else
      raise Mongoid::Errors::DocumentNotFound.new(TempDocument, nil, params[:id])
    end
  end

  def piece
    if @document.piece && File.exist?(@document.piece.content.path)
      send_file(@document.piece.content.path, type: 'application/pdf', filename: @document.piece.content_file_name, x_sendfile: true, disposition: 'inline')
    else
      raise Mongoid::Errors::DocumentNotFound.new(TempDocument, nil, params[:id])
    end
  end

  def select
    @documents = search(document_contains).order_by(sort_column => sort_direction).wait_selection.page(params[:page]).per(params[:per_page])
    @retriever.schedule if @retriever && @retriever.wait_selection?
  end

  def validate
    documents = @customer.temp_documents.find(params[:document_ids] || [])
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
    documents = @customer.temp_documents.fiduceo.includes(:fiduceo_retriever)
    documents = documents.where('fiduceo_metadata.libelle' => /#{Regexp.quote(contains[:name])}/i) unless contains[:name].blank?
    if contains[:service_name]
      retriever_ids = @customer.fiduceo_retrievers.where(name: /#{Regexp.quote(contains[:service_name])}/i).distinct(:_id)
      documents = documents.where(:fiduceo_retriever_id.in => retriever_ids)
    elsif contains[:retriever_id]
      @retriever = @customer.fiduceo_retrievers.find(contains[:retriever_id])
      documents = documents.where(:fiduceo_retriever_id => @retriever.id)
    end
    if contains[:transaction_id]
      @transaction = @customer.fiduceo_transactions.find(contains[:transaction_id])
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
