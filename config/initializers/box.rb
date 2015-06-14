config_file = File.join(Rails.root, 'config', 'box.yml')
raise 'Box configuration file config/box.yml is missing.' unless File.exist?(config_file)

Box.config = YAML::load_file(config_file)[Rails.env]
