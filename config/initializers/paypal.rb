require "paypal"
require "paypal/rails"
require "paypal_wrapper"

config_file = File.join(Rails.root, "config", "paypal.yml")
raise "Paypal configuration file config/paypal.yml is missing." unless File.exists?(config_file)

PaypalWrapper.config  = YAML::load_file(config_file)[Rails.env]
