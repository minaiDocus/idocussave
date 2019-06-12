config_file = File.join(Rails.root, 'config', 'slimpay_checkout.yml')
raise 'Slimpay configuration file config/slimpay_checkout.yml is missing.' unless File.exist?(config_file)

SlimpayCheckout.config = YAML::load_file(config_file)[Rails.env]
