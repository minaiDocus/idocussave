object @preseizure

node :id do |preseizure|
  preseizure.id.to_s
end

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

node :created_at do |preseizure|
  I18n.l(preseizure.created_at)
end

node :updated_at do |preseizure|
  I18n.l(preseizure.updated_at)
end

node :delivery_tried_at do |preseizure|
  I18n.l(preseizure.delivery_tried_at) if preseizure.delivery_tried_at
end

node :user_software do |preseizure|
  if preseizure.user.uses?(:ibiza)
    'Ibiza'
  elsif preseizure.user.uses?(:exact_online) && preseizure.user.exact_online.try(:fully_configured?)
    'Exact Online'
  else
    nil
  end
end

node :is_delivered_to do |preseizure|
  if preseizure.user.uses?(:ibiza) && preseizure.is_delivered_to?('ibiza')
    'ibiza'
  elsif preseizure.user.uses?(:exact_online) && preseizure.user.exact_online.try(:fully_configured?) && preseizure.is_delivered_to?('exact_online')
    'exact_online'
  else
    ''
  end
end

attributes :position, :operation_label, :observation, :piece_number, :currency, :conversion_rate, :third_party, :type, :is_locked, :delivery_message
