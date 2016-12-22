config_file = File.join(Rails.root, 'config', 'slimpay.yml')
raise 'Slimpay configuration file config/slimpay.yml is missing.' unless File.exist?(config_file)


module Slimpay
  CONFIG    = YAML.load_file(File.join(Rails.root, 'config', 'slimpay.yml'))[Rails.env]
  SCIM_HOME = CONFIG['scim_home']
end
