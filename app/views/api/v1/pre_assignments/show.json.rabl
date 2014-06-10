object @pre_assignment

attributes :pack_name, :piece_counts, :comment

node :date do |pre_assignment|
  pre_assignment.date.strftime('%Y-%m-%d %H:%M:%S')
end
