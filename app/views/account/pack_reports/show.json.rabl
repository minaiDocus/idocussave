object @pack_report

node :id do |report|
  report.id.to_s
end

node :name do |report|
  report.name
end

node :created_at do |report|
  I18n.l(report.created_at)
end

node :updated_at do |report|
  I18n.l(report.updated_at)
end

node :last_preseizure_at do |report|
  I18n.l(report.preseizures.last.try(:created_at))
end

node :delivery_tried_at do |report|
  I18n.l(report.delivery_tried_at) if report.delivery_tried_at
end

node :delivery_message do |report|
  report.delivery_message
end

node :user_software do |report|
  if report.user.uses?(:ibiza)
    'Ibiza'
  elsif report.user.uses?(:exact_online) && report.user.exact_online.try(:fully_configured?)
    'Exact Online'
  else
    nil
  end
end

node :is_delivered_to do |report|
  if report.user.uses?(:ibiza) && report.is_delivered_to?('ibiza')
    'ibiza'
  elsif report.user.uses?(:exact_online) && report.user.exact_online.try(:fully_configured?) && report.is_delivered_to?('exact_online')
    'exact_online'
  else
    ''
  end
end

attributes :type, :is_locked
