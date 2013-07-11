module IbizaAPI
  module Config
    ROOT_URL = YAML.load_file("#{Rails.root}/config/ibiza.yml")[Rails.env]['root_url']
    COMPANY_PATH = 'Company'
    ACCOUNTS_PATH = 'Accounts'
    PARTNER_ID = '{BE62697A-C2EE-4757-9A86-747A656FF0D7}'
  end
end