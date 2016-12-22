module IbizaAPI
  module Config
    CONFIG        = YAML.load_file("#{Rails.root}/config/ibiza.yml")[Rails.env]
    ROOT_URL      = CONFIG['root_url']
    PARTNER_ID    = '{BE62697A-C2EE-4757-9A86-747A656FF0D7}'.freeze
    COMPANY_PATH  = 'Company'.freeze
    ACCOUNTS_PATH = 'Accounts'.freeze
  end
end
