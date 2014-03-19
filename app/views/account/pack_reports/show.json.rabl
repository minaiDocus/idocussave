object @pack_report

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

node :download_xml do |report|
  current_user.is_admin
end

attributes :id, :is_delivered, :type, :is_locked
