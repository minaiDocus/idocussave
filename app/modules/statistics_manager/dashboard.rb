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
    calculate_operations_statistics +
    calculate_software_owner_statistics +
    calculate_documents_uploaded_by_api_statistics
  end

  def self.statistic_names
    statistics_to_be_generated.map(&:first)
  end

private

  def self.calculate_temp_documents_statistics
    [
      ['ready_temp_documents_count', TempDocument.with(period).ready.count],
      ['locked_temp_documents_count', TempDocument.with(period).locked.count],
      ['processed_temp_documents_count', TempDocument.with(period).processed.count],
      ['unreadable_temp_documents_count', TempDocument.with(period).unreadable.count],
      ['ocr_needed_temp_documents_count', TempDocument.with(period).ocr_needed.count],
      ['wait_selection_temp_documents_count', TempDocument.with(period).wait_selection.count],
      ['bundle_needed_temp_documents_count', TempDocument.with(period).bundle_needed.count],
      ['ocr_layer_applied_temp_documents_count', TempDocument.with(period).ocr_layer_applied.sum(:pages_number).to_i]
    ]
  end

  def self.calculate_remote_files_statistics
    [
      ['not_processed_retryable_dropbox_extended_remote_files_count', RemoteFile.with(period).of_service('Dropbox Extended').not_processed.retryable.count],
      ['not_processed_not_retryable_dropbox_extended_remote_files_count', RemoteFile.with(period).of_service('Dropbox Extended').not_processed.not_retryable.count],

      ['not_processed_retryable_dropbox_remote_files_count', RemoteFile.with(period).of_service('Dropbox').not_processed.retryable.count],
      ['not_processed_not_retryable_dropbox_remote_files_count', RemoteFile.with(period).of_service('Dropbox').not_processed.not_retryable.count],

      ['not_processed_retryable_google_drive_remote_files_count', RemoteFile.with(period).of_service('Google Drive').not_processed.retryable.count],
      ['not_processed_not_retryable_google_drive_remote_files_count', RemoteFile.with(period).of_service('Google Drive').not_processed.not_retryable.count],

      ['not_processed_retryable_box_remote_files_count', RemoteFile.with(period).of_service('Box').not_processed.retryable.count],
      ['not_processed_not_retryable_box_remote_files_count', RemoteFile.with(period).of_service('Box').not_processed.not_retryable.count],

      ['not_processed_retryable_ftp_remote_files_count', RemoteFile.with(period).of_service('FTP').not_processed.retryable.count],
      ['not_processed_not_retryable_ftp_remote_files_count', RemoteFile.with(period).of_service('FTP').not_processed.not_retryable.count],

      ['not_processed_retryable_mcf_remote_files_count', RemoteFile.with(period).of_service('My Company Files').not_processed.retryable.count],
      ['not_processed_not_retryable_mcf_remote_files_count', RemoteFile.with(period).of_service('My Company Files').not_processed.not_retryable.count]
    ]
  end

  def self.calculate_retrievers_statistics
    user_ids = User.customers.active_at(Time.now).pluck(:id)
    [
      ['retrievers_count', Retriever.with(period).count],
      ['retriever_users_count', UserOptions.where(updated_at: period, user_id: user_ids, is_retriever_authorized: true).count],
      ['active_retriever_users_count', BudgeaAccount.with(period).count],
      ['retrievers_ready_count', Retriever.with(period).ready.count],
      ['retrievers_waiting_selections_count', Retriever.with(period).waiting_selection.count],
      ['retrievers_errors_count', Retriever.with(period).error.count],
      ['retrieved_data_not_processed_count', RetrievedData.with(period).not_processed.count],
      ['retrieved_data_errors_count', RetrievedData.with(period).error.count]
    ]
  end

  def self.calculate_documents_statistics
    [
      ['documents_count', Document.with(period).count],
      ['retrieved_documents_count', Document.with(period).retrieved.count],
      ['scanned_documents_count', Document.with(period).scanned.count],
      ['uploaded_documents_count', Document.with(period).uploaded.count],
      ['dematbox_scanned_documents_count', Document.with(period).dematbox_scanned.count],
      ['not_clean_not_mixed_documents_count', Document.with(period).not_clean.not_mixed.count],
      ['not_extracted_not_mixed_documents_count', Document.with(period).not_extracted.not_mixed.count],
    ]
  end

  def self.calculate_operations_statistics
    [
      ['capidocus_operations_count', Operation.select_with('capidocus', period).size],
      ['budgea_operations_count', Operation.select_with('budgea', period).size],
      ['bridge_operations_count', Operation.select_with('bridge', period).size],
      ['capidocus_not_processed_locked_operations_count', Operation.select_with('capidocus', period).not_processed.locked.size],
      ['budgea_not_processed_locked_operations_count', Operation.select_with('budgea', period).not_processed.locked.size],
      ['bridge_not_processed_locked_operations_count', Operation.select_with('bridge', period).not_processed.locked.size],
      ['capidocus_not_processed_not_locked_operations_count', Operation.select_with('capidocus', period).not_processed.not_locked.size],
      ['budgea_not_processed_not_locked_operations_count', Operation.select_with('budgea', period).not_processed.not_locked.size],
      ['bridge_not_processed_not_locked_operations_count', Operation.select_with('bridge', period).not_processed.not_locked.size],
      ['capidocus_processed_operations_count', Operation.select_with('capidocus', period).processed.size],
      ['budgea_processed_operations_count', Operation.select_with('budgea', period).processed.size],
      ['bridge_processed_operations_count', Operation.select_with('bridge', period).processed.size],
      ['operations_count', Operation.with(period).count],
      ['not_processed_locked_operations_count', Operation.with(period).not_processed.locked.size],
      ['not_processed_not_locked_operations_count', Operation.with(period).not_processed.not_locked.size],
      ['processed_operations_count', Operation.with(period).processed.size],
    ]
  end

  def self.calculate_software_owner_statistics
    software_infos  = []

    Interfaces::Software::Configuration::SOFTWARES.each do |software_name|
      organizations  = Interfaces::Software::Configuration.softwares[software_name.to_sym].where(owner_type: 'Organization', is_used: true)
      customers      = Interfaces::Software::Configuration.softwares[software_name.to_sym].where(owner_type: 'User', is_used: true)

      software_infos << [ "#{software_name}_organizations_count", organizations.size ]
      software_infos << [ "#{software_name}_users_count", customers.size ]
    end

    software_infos
  end

  def self.calculate_documents_uploaded_by_api_statistics
    documents_uploaded_by_api  = []
    TempDocument.api_names.each do |api_name|
      documents_uploaded_by_api << ["#{api_name[:api_name]}_temp_documents_count", api_name[:count]]
    end

    documents_uploaded_by_api
  end

  def self.period
    [30.days.ago..Time.now]
  end

end
