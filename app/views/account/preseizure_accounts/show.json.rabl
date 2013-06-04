object @preseizure_account

attributes :id, :type, :number, :lettering

child :entries do
  attributes :id, :type, :amount

  node :number do |entry|
    entry.number.to_i
  end
end