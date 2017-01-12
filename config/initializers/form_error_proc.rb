ActionView::Base.field_error_proc = proc do |html_tag, _instance|
  if html_tag =~ /<(input|label|textarea|select)/
    error_class = 'error'
    nodes = Hpricot(html_tag)

    nodes.each_child { |node| node[:class] = node.classes.push(error_class).join(' ') unless !node.elem? || node[:type] == 'hidden' || node.classes.include?(error_class) }
    nodes.to_html
  else
    html_tag
  end
end
