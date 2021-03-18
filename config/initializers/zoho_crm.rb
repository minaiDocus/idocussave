module ZohoCrm
  CONFIG = YAML.load_file("#{Rails.root}/config/zoho_crm.yml")[Rails.env]

  BASE_URI          = CONFIG['base_uri']
  USER_TOKEN        = CONFIG['user_token']
  REFRESH_TOKEN     = CONFIG['refresh_token']
  CLIENT_ID         = CONFIG['client_id']
  CLIENT_SECRET     = CONFIG['client_secret']
  GRANT_TYPE        = CONFIG['grant_type']
  CODE              = CONFIG['code']
  REDIRECT_URI      = CONFIG['redirect_uri']
  REFRESH_TOKEN_URL = 'https://accounts.zoho.com'
end
