object @preseizure

node :name do |preseizure|
  preseizure.piece.name
end

node :date do |preseizure|
  preseizure.date.try(:to_date)
end

node :deadline_date do |preseizure|
  preseizure.deadline_date.try(:to_date)
end

node :period_date do |preseizure|
  preseizure.period_date.try(:to_date)
end

node :url do |preseizure|
  preseizure.piece.content.url
end

attributes :id, :position, :observation, :piece_number, :amount, :currency, :conversion_rate, :third_party, :is_delivered