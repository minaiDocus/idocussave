object @preseizure

node :name do |preseizure|
  preseizure.piece_name
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
  preseizure.piece_content_url
end

node :journal do |preseizure|
  preseizure.piece.journal rescue nil
end

node :piece_name do |preseizure|
  preseizure.piece.name rescue nil
end

node :amount do |preseizure|
  format_price_00 preseizure.amount_in_cents rescue nil
end

node :created_at do |report|
  I18n.l(report.created_at)
end

node :updated_at do |report|
  I18n.l(report.updated_at)
end

node :delivery_tried_at do |report|
  I18n.l(report.delivery_tried_at) if report.delivery_tried_at
end

attributes :id, :position, :observation, :piece_number, :currency, :conversion_rate, :third_party, :is_delivered, :type, :is_locked
