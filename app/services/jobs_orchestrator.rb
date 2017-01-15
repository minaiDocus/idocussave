class JobsOrchestrator
  def self.perform
    if Sidekiq::Queue.new("pre_assignments_delivery").size == 0
      DeliverPreAssignmentsWorker.perform_async unless JobsOrchestrator.check_if_in_queue("DeliverPreAssignmentsWorker")
    end

    if Sidekiq::Queue.new("grouping_delivery").size == 0
      TempPack.bundle_needed.not_recently_updated.order(updated_at: :asc).each do |temp_pack|
        temp_pack.temp_documents.bundle_needed.by_position.each do |temp_document|
          DeliverToGroupingWorker.perform_async(temp_document.id) unless JobsOrchestrator.check_if_in_queue("DeliverToGroupingWorker", "#{temp_document.id}")
        end
      end
    end

    if Sidekiq::Queue.new("process_and_deliver_grouped").size == 0
      TempPack.not_processed.each do |temp_pack|
        ProcessAndDeliverGroupedDocumentWorker.perform_async(temp_pack.id) unless JobsOrchestrator.check_if_in_queue("ProcessAndDeliverGroupedDocumentWorker", "#{temp_pack.id}")
      end
    end

    if Sidekiq::Queue.new("retrieve_from_grouping").size == 0
      processable_results = Dir.glob(AccountingWorkflow.grouping_dir.join('output/*.xml')).select do |file_path|
                                            File.atime(file_path) < 1.minute.ago
                                          end

      processable_results.map do |file_path|
        RetrieveFromGroupingWorker.perform_async(file_path) unless JobsOrchestrator.check_if_in_queue("RetrieveFromGroupingWorker", "#{file_path}")
      end
    end

    if Sidekiq::Queue.new("retrieve_preseizures").size == 0
      RetrievePreseizuresWorker.perform_async unless JobsOrchestrator.check_if_in_queue("RetrievePreseizuresWorker")
    end

    if Sidekiq::Queue.new("sync_remote_files").size == 0
      SyncRemoteFilesWorker.perform_async unless JobsOrchestrator.check_if_in_queue("SyncRemoteFilesWorker")
    end

    if Sidekiq::Queue.new("remote_file_delivery").size == 0
      DeliverRemoteFilesWorker.perform_async('dbx') unless JobsOrchestrator.check_if_in_queue("DeliverRemoteFilesWorker", "dbx")
      DeliverRemoteFilesWorker.perform_async('dbb') unless JobsOrchestrator.check_if_in_queue("DeliverRemoteFilesWorker", "dbb")
      DeliverRemoteFilesWorker.perform_async('box') unless JobsOrchestrator.check_if_in_queue("DeliverRemoteFilesWorker", "box")
      DeliverRemoteFilesWorker.perform_async('kwg') unless JobsOrchestrator.check_if_in_queue("DeliverRemoteFilesWorker", "kwg")
      DeliverRemoteFilesWorker.perform_async('ftp') unless JobsOrchestrator.check_if_in_queue("DeliverRemoteFilesWorker", "ftp")
      DeliverRemoteFilesWorker.perform_async('gdr') unless JobsOrchestrator.check_if_in_queue("DeliverRemoteFilesWorker", "gdr")
    end

    if Sidekiq::Queue.new('retrieve_emailed_document').size == 0
      RetrieveEmailedDocumentWorker.perform_async unless JobsOrchestrator.check_if_in_queue("RetrieveEmailedDocumentWorker")
    end
  end


  def self.running_workers
    workers = []

    Sidekiq::Workers.new.each do |server, identifier, worker|
      workers << { class_name: worker['payload']["class"], id: worker['payload']['args'].first }
    end

    workers
  end


  def self.check_if_in_queue(class_name, id = nil)
    true if running_workers.detect { |worker| worker[:class_name] == class_name && worker[:id].to_s == id.to_s }
  end
end

