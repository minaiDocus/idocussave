config_file = File.join(Rails.root, 'config', 'ftp_delivery.yml')
raise 'FTP configuration file config/ftp_delivery.yml is missing.' unless File.exist?(config_file)

module FTPDeliveryConfiguration
  CONFIG       = YAML.load_file(File.join(Rails.root, 'config', 'ftp_delivery.yml'))[Rails.env]

  FTP_PATH     = CONFIG['path']
  FTP_SERVER   = CONFIG['server']
  FTP_USERNAME = CONFIG['username']
  FTP_PASSWORD = CONFIG['password']
  FTP_PROVIDER = CONFIG['provider']

  IS_ENABLED   = CONFIG['is_enabled']
end
