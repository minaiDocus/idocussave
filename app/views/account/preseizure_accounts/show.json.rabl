object @preseizure_account

attributes :id, :type, :number, :lettering

child :entries do
  attributes :id, :type

  node :amount do |entry|
    format_price_with_dot entry.amount_in_cents rescue nil
  end

  node :number do |entry|
    entry.number.to_i
  end
end
