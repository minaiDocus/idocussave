BEARER_CONFIG = YAML.load_file('config/bearer.yml').freeze

Bearer.init_config do |config|
  config.secret_key = BEARER_CONFIG['secret']
end