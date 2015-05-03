object @pre_assignment

node :pack_name do |e|
  e.name
end

node :piece_counts do |e|
  e.document_count
end

node :comment do |e|
  e.message
end

node :date do |pre_assignment|
  pre_assignment.date.strftime('%Y-%m-%d %H:%M:%S')
end
