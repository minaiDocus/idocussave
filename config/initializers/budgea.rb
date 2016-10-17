config_file = File.join(Rails.root, 'config', 'budgea.yml')
raise 'Budgea configuration file config/budgea.yml is missing.' unless File.exist?(config_file)

Budgea.config = YAML::load_file(config_file)[Rails.env]
