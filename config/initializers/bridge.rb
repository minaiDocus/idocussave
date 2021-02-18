BRIDGE_CONFIG = YAML.load_file('config/bridge.yml').freeze

BridgeBankin.configure do |config|
  config.api_client_id = BRIDGE_CONFIG["api_client_id"]
  config.api_client_secret = BRIDGE_CONFIG["api_client_secret"]
end