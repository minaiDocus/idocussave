object @pack_report

node :name do |report|
  report.pack.name.sub(' all','')
end

attributes :id, :is_delivered