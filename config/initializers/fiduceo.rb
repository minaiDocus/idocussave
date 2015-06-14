config_file = File.join(Rails.root, 'config', 'fiduceo.yml')
raise 'Fiduceo configuration file config/fiduceo.yml is missing.' unless File.exist?(config_file)

Fiduceo.config = YAML::load_file(config_file)[Rails.env]
