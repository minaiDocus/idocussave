# -*- encoding : UTF-8 -*-
class Account::RetrievedDocumentsController < Account::FiduceoController
  layout 'layouts/account/retrievers'
  before_filter :load_retriever_ids
  before_filter :load_document, except: :index

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
      retriever_ids = @user.fiduceo_retrievers.where(name: /#{Regexp.quote(contains[:service_name])}/i).distinct(:_id)
      documents = documents.where(:fiduceo_retriever_id.in => retriever_ids)
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
