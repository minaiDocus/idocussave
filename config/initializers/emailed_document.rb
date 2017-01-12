config_file = File.join(Rails.root, 'config', 'emailed_document.yml')
raise 'EmailedDocument configuration file config/emailed_document.yml is missing.' unless File.exist?(config_file)

EmailedDocument.config = YAML.load_file(config_file)[Rails.env]
