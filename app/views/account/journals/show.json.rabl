object @journal

attributes :id, :slug, :name, :description, :entry_type, :account_number, :charge_account, :request_type, :is_default, :client_ids, :requested_client_ids

node :entry_name do |journal|
  t("mongoid.models.account_book_type.attributes.entry_type_#{journal.entry_type}")
end