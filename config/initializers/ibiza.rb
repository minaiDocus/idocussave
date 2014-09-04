module IbizaAPI
  module Config
    CONFIG             = YAML.load_file("#{Rails.root}/config/ibiza.yml")[Rails.env]
    ROOT_URL           = CONFIG['root_url']
    COMPANY_PATH       = 'Company'
    ACCOUNTS_PATH      = 'Accounts'
    PARTNER_ID         = '{BE62697A-C2EE-4757-9A86-747A656FF0D7}'
    NOTIFY_ON_DELIVERY = CONFIG['notify_on_delivery']
    NOTIFY_TO          = CONFIG['notify_to']
  end
end
