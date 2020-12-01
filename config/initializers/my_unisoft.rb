config_file = File.join(Rails.root, 'config', 'my_unisoft.yml')
raise 'MyUnisoft configuration file config/my_unisoft.yml is missing.' unless File.exist?(config_file)

MyUnisoftLib::Api::Util.config = YAML::load_file(config_file)[Rails.env]