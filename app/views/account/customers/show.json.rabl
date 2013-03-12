object @customer

attributes :id, :first_name, :last_name, :company, :code, :is_editable, :account_book_type_ids, :requested_account_book_type_ids

node :request_type do |customer|
  case customer.request_type
    when 0
      ''
    when 1
      'adding'
    when 2
      'updating'
    when 3
      'removing'
  end
end

node :entry_name do |customer|
  t("mongoid.models.account_book_type.attributes.entry_type_#{customer.request_type}")
end