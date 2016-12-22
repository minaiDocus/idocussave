module DematboxConfig
  CONFIG = YAML.load_file("#{Rails.root}/config/dematbox.yml")[Rails.env]

  WSDL = CONFIG['wsdl']

  NAMESPACE = CONFIG['namespace']

  LOGGER    = Rails.env == 'production' ? Rails.logger : Logger.new(STDOUT)
  LOG_LEVEL = CONFIG['log_level']

  USERNAME    = CONFIG['username']
  PASSWORD    = CONFIG['password']
  OPERATOR_ID = CONFIG['operator_id']

  SSL_VERSION       = CONFIG['ssl_version'].to_sym
  SSL_CERT_FILE     = CONFIG['ssl_cert_file']
  SSL_VERIFY_MODE   = CONFIG['ssl_verify_mode'].to_sym
  SSL_CA_CERT_FILE  = CONFIG['ssl_ca_cert_file']
  SSL_CERT_KEY_FILE = CONFIG['ssl_cert_key_file']
end
