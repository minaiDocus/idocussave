# Be sure to restart your server when you modify this file.

# Add new mime types for use in respond_to blocks:
# Mime::Type.register "text/richtext", :rtf
# Mime::Type.register_alias "text/html", :iphone
Mime::Type.register 'application/vnd.ms-excel', :xls
Mime::Type.register 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', :xlsx

text_html = MIME::Types['text/html'].first
text_html.extensions << 'eml'
#MIME::Types.index_extensions text_html
