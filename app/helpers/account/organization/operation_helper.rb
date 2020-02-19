# frozen_string_literal: true

module Account::Organization::OperationHelper
  def is_operation_pre_assigned(operation)
    if operation.processed_at.present?
      t('yes_value')
    elsif operation.is_locked
      t('no_value')
    elsif operation.forced_processing_at.nil? && Time.now < (operation.created_at + 7.days)
      begin
        "dans #{distance_of_time_in_words(Time.now, operation.created_at + 7.days)}"
      rescue
        "le #{(operation.created_at + 7.days).strftime('%d/%m/%Y')}"
      end
    elsif operation.deleted_at.present?
      'supprimée'
    else
      'maintenant'
    end
  end
end