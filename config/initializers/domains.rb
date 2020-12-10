module Domains
  CONFIG = YAML.load_file("#{Rails.root}/config/domains.yml")[Rails.env]

  PROTOCOL = CONFIG['protocol']
  PORT     = CONFIG['port']
  HOST     = CONFIG['host']

  BASE_URL = PROTOCOL + '://' + HOST + (PORT ? ":#{PORT}" : '')
end