object @journal

attributes :id, :slug, :name, :pseudonym, :description, :entry_type, :default_account_number, :account_number, :default_charge_account, :charge_account, :vat_account, :anomaly_account, :is_default

node :client_ids do |journal|
  journal.client_ids.select do |client_id|
    client_id.in? @customer_ids
  end
end

node :entry_name do |journal|
  t("mongoid.models.account_book_type.attributes.entry_type_#{journal.entry_type}")
end
