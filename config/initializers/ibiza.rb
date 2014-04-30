module IbizaAPI
  module Config
    CONFIG          = YAML.load_file("#{Rails.root}/config/ibiza.yml")[Rails.env]
    ROOT_URL        = CONFIG['root_url']
    COMPANY_PATH    = 'Company'
    ACCOUNTS_PATH   = 'Accounts'
    PARTNER_ID      = '{BE62697A-C2EE-4757-9A86-747A656FF0D7}'
    NOTIFY_ERROR_TO = CONFIG['notify_error_to']
  end
end
