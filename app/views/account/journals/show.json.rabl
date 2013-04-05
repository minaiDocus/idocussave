object @journal

attributes :id, :slug, :name, :description, :entry_type, :default_account_number, :account_number, :default_charge_account, :charge_account, :vat_account, :anomaly_account, :is_default, :client_ids, :requested_client_ids

node :request_type do |journal|
  case journal.request.status
    when ''
      ''
    when 'create'
      'adding'
    when 'update'
      'updating'
    when 'destroy'
      'removing'
  end
end

node :entry_name do |journal|
  t("mongoid.models.account_book_type.attributes.entry_type_#{journal.entry_type}")
end