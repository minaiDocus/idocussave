config_file = File.join(Rails.root, 'config', 'dematbox_service_api.yml')
raise 'DematboxServiceApi configuration file config/dematbox_service_api.yml is missing.' unless File.exist?(config_file)

DematboxServiceApi.config = YAML.load_file(config_file)[Rails.env]
