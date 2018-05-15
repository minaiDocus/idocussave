class StatisticsManager::Dashboard
  def self.generate_statistics
    StatisticsManager.create_statistics(statistics_to_be_generated)
    true
  end

  def self.statistics_to_be_generated
    calculate_temp_documents_statistics +
    calculate_remote_files_statistics +
    calculate_retrievers_statistics +
    calculate_documents_statistics +
    calculate_operations_statistics
  end

  def self.statistic_names
    statistics_to_be_generated.map(&:first)
  end

private

  def self.calculate_temp_documents_statistics
    [
      ['ready_temp_documents_count', TempDocument.ready.count],
      ['locked_temp_documents_count', TempDocument.locked.count],
      ['processed_temp_documents_count', TempDocument.processed.count],
      ['unreadable_temp_documents_count', TempDocument.unreadable.count],
      ['ocr_needed_temp_documents_count', TempDocument.ocr_needed.count],
      ['wait_selection_temp_documents_count', TempDocument.wait_selection.count],
      ['bundle_needed_temp_documents_count', TempDocument.bundle_needed.count],
      ['ocr_layer_applied_temp_documents_count', TempDocument.ocr_layer_applied.sum(:pages_number).to_i]
    ]
  end

  def self.calculate_remote_files_statistics
    [
      ['not_processed_retryable_dropbox_extended_remote_files_count', RemoteFile.of_service('Dropbox Extended').not_processed.retryable.count],
      ['not_processed_not_retryable_dropbox_extended_remote_files_count', RemoteFile.of_service('Dropbox Extended').not_processed.not_retryable.count],

      ['not_processed_retryable_dropbox_remote_files_count', RemoteFile.of_service('Dropbox').not_processed.retryable.count],
      ['not_processed_not_retryable_dropbox_remote_files_count', RemoteFile.of_service('Dropbox').not_processed.not_retryable.count],

      ['not_processed_retryable_google_drive_remote_files_count', RemoteFile.of_service('Google Drive').not_processed.retryable.count],
      ['not_processed_not_retryable_google_drive_remote_files_count', RemoteFile.of_service('Google Drive').not_processed.not_retryable.count],

      ['not_processed_retryable_box_remote_files_count', RemoteFile.of_service('Box').not_processed.retryable.count],
      ['not_processed_not_retryable_box_remote_files_count', RemoteFile.of_service('Box').not_processed.not_retryable.count],

      ['not_processed_retryable_ftp_remote_files_count', RemoteFile.of_service('FTP').not_processed.retryable.count],
      ['not_processed_not_retryable_ftp_remote_files_count', RemoteFile.of_service('FTP').not_processed.not_retryable.count],

      ['not_processed_retryable_knowings_remote_files_count', RemoteFile.of_service('Knowings').not_processed.retryable.count],
      ['not_processed_not_retryable_knowings_remote_files_count', RemoteFile.of_service('Knowings').not_processed.not_retryable.count]
    ]
  end

  def self.calculate_retrievers_statistics
    user_ids = User.customers.active_at(Time.now).pluck(:id)
    [
      ['retrievers_count', Retriever.count],
      ['retriever_users_count', UserOptions.where(user_id: user_ids, is_retriever_authorized: true).count],
      ['active_retriever_users_count', BudgeaAccount.count],
      ['retrievers_ready_count', Retriever.ready.count],
      ['retrievers_waiting_selections_count', Retriever.waiting_selection.count],
      ['retrievers_errors_count', Retriever.error.count],
      ['retrieved_data_not_processed_count', RetrievedData.not_processed.count],
      ['retrieved_data_errors_count', RetrievedData.error.count]
    ]
  end

  def self.calculate_documents_statistics
    [
      ['documents_count', Document.count],
      ['retrieved_documents_count', Document.retrieved.count],
      ['scanned_documents_count', Document.scanned.count],
      ['uploaded_documents_count', Document.uploaded.count],
      ['dematbox_scanned_documents_count', Document.dematbox_scanned.count],
      ['not_clean_not_mixed_documents_count', Document.not_clean.not_mixed.count],
      ['not_extracted_not_mixed_documents_count', Document.not_extracted.not_mixed.count],
    ]
  end

  def self.calculate_operations_statistics
    [
      ['operations_count', Operation.count],
      ['retrieved_operations_count', Operation.retrieved.count],
      ['other_operations_count', Operation.other.count],
      ['processed_operations_count', Operation.processed.count],
      ['not_processed_locked_operations_count', Operation.not_processed.locked.count],
      ['not_processed_not_locked_operations_count', Operation.not_processed.not_locked.count],
    ]
  end

end
