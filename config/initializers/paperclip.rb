Paperclip.options[:command_path] = "/usr/bin"
Paperclip::Attachment.default_options[:url] = "/system/:attachment/:id/:style/:filename" unless Rails.env.test?
Paperclip::Attachment.default_options[:url] = "/system_test/:attachment/:id/:style/:filename" if Rails.env.test?
Paperclip::Attachment.default_options[:path] = ":rails_root/public:url"
Paperclip::Attachment.default_options[:storage] = :filesystem
