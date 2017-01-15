class StatisticsManager::Generator
  def self.generate_dashboard_statistics
    statistics_to_be_generated = calculate_temp_documents_statistics + calculate_remote_files_statistics + 
                                              calculate_fiduceo_retrievers_statistics + calculate_documents_statistics + calculate_operations_statistics

    StatisticsManager.create_statistics(statistics_to_be_generated)
  end


  private

  def self.calculate_temp_documents_statistics
    [
      ['ready_temp_documents_count' , TempDocument.ready.count],
      ['locked_temp_documetns_count' ,TempDocument.locked.count],
      ['processed_temp_documents_count' , TempDocument.processed.count],
      ['unreadable_temp_documents_count' , TempDocument.unreadable.count],
      ['ocr_needed_temp_documents_count' , TempDocument.ocr_needed.count],
      ['wait_selection_temp_documents_count' , TempDocument.wait_selection.count],
      ['bundle_needed_temp_documents_count', TempDocument.bundle_needed.count],
      ['ocr_layer_applied_temp_documents_count', TempDocument.ocr_layer_applied.sum(:pages_number).to_i]
    ]
  end


  def self.calculate_remote_files_statistics
    [
      ['not_processed_retryable_ftp_remote_files_count' , RemoteFile.of_service('FTP').not_processed.retryable.count],
      ['not_processed_not_retryable_ftp_remote_files_count', RemoteFile.of_service('FTP').not_processed.not_retryable.count],

      ['not_processed_retryable_dropbox_remote_files_count', RemoteFile.of_service('Dropbox').not_processed.retryable.count],
      ['not_processed_not_retryable_dropbox_remote_files_count', RemoteFile.of_service('Dropbox').not_processed.not_retryable.count],

      ['not_processed_retryable_box_extentend_remote_files_count', RemoteFile.of_service('Box').not_processed.retryable.count],
      ['not_processed_not_retryable_box_extentend_remote_files_count', RemoteFile.of_service('Box').not_processed.not_retryable.count],

      ['not_processed_not_retryable_knowings_remote_files_count', RemoteFile.of_service('Knowings').not_processed.not_retryable.count],
      ['not_processed_retryable_knowings_extentend_remote_files_count', RemoteFile.of_service('Knowings').not_processed.retryable.count],

      ['not_processed_retryable_dropbox_extentended_remote_files_count', RemoteFile.of_service('Dropbox Extended').not_processed.retryable.count],
      ['not_processed_not_retryable_dropbox_extentended_remote_files_count', RemoteFile.of_service('Dropbox Extended').not_processed.not_retryable.count],
      
      ['not_processed_retryable_google_drive_extentend_remote_files_count', RemoteFile.of_service('Google Drive').not_processed.retryable.count],
      ['not_processed_not_retryable_google_drive_extentend_remote_files_count', RemoteFile.of_service('Google Drive').not_processed.not_retryable.count]
    ]
  end


  def self.calculate_fiduceo_retrievers_statistics
    [
      # ['error_fiduceo_retrievers_count', FiduceoRetriever.error.count],
      # ['scheduled_fiduceo_retrievers_count', FiduceoRetriever.scheduled.count],
      # ['processing_fiduceo_retrievers_count', FiduceoRetriever.processing.count],
      # ['wait_selection_fiduceo_retrievers_count', FiduceoRetriever.wait_selection.count],
      # ['wait_for_user_action_fiduceo_retrievers_count', FiduceoRetriever.wait_for_user_action.count]
    ]
  end


  def self.calculate_documents_statistics
    [
      ['documents_count', Document.count],
      ['fiduceo_documents_count', Document.retrieved.count],
      ['scanned_documents_count', Document.scanned.count],
      ['uploaded_documents_count', Document.uploaded.count],
      ['dematbox_scanned_documents_count', Document.dematbox_scanned.count],
      ['not_clean_not_mixed_documents_count', Document.not_clean.not_mixed.count],
      ['not_extracted_not_mixed_documents_count' ,Document.not_extracted.not_mixed.count],
    ]
  end


  def self.calculate_operations_statistics
    [
      ['operations_count', Operation.count],
      ['other_operations_count', Operation.other.count],
      ['fiduceo_operations_count' ,Operation.retrieved.count],
      ['processed_operations_count', Operation.processed.count],
      ['not_processed_locked_operations_count', Operation.not_processed.locked.count],
      ['not_processed_not_locked_operations_count', Operation.not_processed.not_locked.count],
    ]
  end
end