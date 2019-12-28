module BootstrapIconHelper
  def icon(options)
    glyphicon(options[:icon])

    # icon_name = options.delete(:icon)

    # options[:class] ||= ''
    # options[:class] << ' icon-' << icon_name.to_s if icon_name

    # content_tag :i, '', options
  end

  def icon_link_to(path, options = {}, link_options = {})
    link_to icon(options), path, link_options
  end
end
