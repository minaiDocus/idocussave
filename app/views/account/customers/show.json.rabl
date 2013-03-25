object @customer

attributes :id, :first_name, :last_name, :company, :code, :is_editable, :account_book_type_ids, :requested_account_book_type_ids

node :request_type do |customer|
  case customer.request.status
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

node :entry_name do |customer|
  t("mongoid.models.account_book_type.attributes.entry_type_#{customer.request_type}")
end