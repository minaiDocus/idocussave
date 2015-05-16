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

node :delivery_tried_at do |report|
  I18n.l(report.delivery_tried_at) if report.delivery_tried_at
end

node :delivery_message do |report|
  report.delivery_message
end

attributes :is_delivered, :type, :is_locked
