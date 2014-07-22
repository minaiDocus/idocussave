object @journal

attributes :id, :slug, :name, :pseudonym, :description, :entry_type, :default_account_number, :account_number, :default_charge_account, :charge_account, :vat_account, :anomaly_account, :is_default, :client_ids

node :entry_name do |journal|
  t("mongoid.models.account_book_type.attributes.entry_type_#{journal.entry_type}")
end
