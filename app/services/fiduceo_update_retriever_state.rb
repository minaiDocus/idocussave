### Temporary class to handle the new way we use Fiduceo since v3 migration ###
class FiduceoUpdateRetrieverState
  # Refresh all Fifuceo retriever's statuses
  def self.refresh_all
    FiduceoRetriever.all.each do |retriever|
      FiduceoUpdateRetrieverState.new(retriever).update_documents_to_retrieve
    end
  end


  def initialize(retriever)
    @retriever = retriever
  end


  def execute
    client = Fiduceo::Client.new(@retriever.user.fiduceo_id)
    retriever_data = client.retriever(@retriever.fiduceo_id)

     if retriever_data && !retriever_data.is_a?(Integer) && retriever_data["retrieverStatusList"]
      status = retriever_data["retrieverStatusList"]["retrieverStatus"].is_a?(Array) ? retriever_data["retrieverStatusList"]["retrieverStatus"].first["status"] : retriever_data["retrieverStatusList"]["retrieverStatus"]["status"]

      if status.in?(FiduceoTransaction::ERROR_STATUSES)
        state = 'error'
      elsif status.in?(FiduceoTransaction::SUCCESS_STATUSES)
        state = 'scheduled'
      elsif status == 'WAIT_FOR_USER_ACTION'
        state = 'wait_for_user_action'
      end

      @retriever.update(transaction_status: status, state: state)

      if status == 'COMPLETED'
        FiduceoUpdateRetrieverState.update_documents_to_retrieve
      end
    end
  end


  def update_documents_to_retrieve
    client = Fiduceo::Client.new(@retriever.user.fiduceo_id)
    documents = client.documents

    if documents != [] && documents["document"]
      pending_documents = []

      if documents["document"].is_a?(Array)
        documents["document"].each do |document|
          pending_documents << document["id"] if document["retrieverId"] && document["retrieverId"] == @retriever.fiduceo_id
        end
      else
        pending_documents << documents["id"] if documents["retrieverId"] && documents["retrieverId"] == @retriever.fiduceo_id
      end

      @retriever.update(pending_document_ids: pending_documents)
    end
  end
end
