object @preseizure_account

attributes :type, :number, :lettering

node :analytic_reference do |preseizure_account|
  preseizure_account.preseizure.analytic_reference.to_json
end

node :unit do |preseizure_account|
  preseizure_account.preseizure.unit.to_s
end

node :id do |preseizure_account|
  preseizure_account.id.to_s
end

child :entries => :entries do
  attributes :type

  node :id do |entry|
    entry.id.to_s
  end

  node :amount do |entry|
    format_price_with_dot entry.amount_in_cents rescue nil
  end

  node :number do |entry|
    entry.number.to_i
  end
end
