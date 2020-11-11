class PonctualScripts::Archive::JobsOrchestrator
  # TODO: optimize checks
  def self.perform
    # Send documents to operators for grouping
    # TempPack.bundle_processable.each do |temp_pack|
    #   temp_pack.temp_documents.bundle_needed.by_position.each do |temp_document|
    #     UniqueJobs.for "SendToGrouping-#{temp_document.id}" do
    #       SendToGroupingWorker.perform_async(temp_document.id)
    #     end
    #   end
    # end
    # Group documents
    # Dir.glob(AccountingWorkflow.grouping_dir.join('output/*.xml')).select do |file_path|
    #   File.atime(file_path) < 1.minute.ago
    # end.map do |file_path|
    #   UniqueJobs.for "GroupDocument-#{file_path}" do
    #     GroupDocumentWorker.perform_async(file_path)
    #   end
    # end
    # Publish documents and initialize delivery
    # TempPack.not_processed.each do |temp_pack|
    #   UniqueJobs.for "PublishDocument-#{temp_pack.id}", 2.hours do
    #     PublishDocumentWorker.perform_async(temp_pack.id)
    #   end
    # end
    # Process retrieved data
    # RetrievedData.not_processed.each do |retrieved_data|
    #   UniqueJobs.for "ProcessRetrievedDataWorker-#{retrieved_data.id}" do
    #     DataProcessor::RetrievedDataWorker.perform_async retrieved_data.id
    #   end
    # end
  end
end
