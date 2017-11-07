Paperclip.options[:command_path] = '/usr/bin'
Paperclip::Attachment.default_options[:storage] = :filesystem
# Needed for RetrievedData
Paperclip.options[:content_type_mappings] = { blob: 'text/plain' }
