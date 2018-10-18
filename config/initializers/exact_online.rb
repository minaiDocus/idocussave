config_file = File.join(Rails.root, 'config', 'exact_online.yml')
raise 'ExactOnlineSdk configuration file config/exact_online.yml is missing.' unless File.exist?(config_file)

ExactOnlineSdk.config = YAML::load_file(config_file)[Rails.env]
