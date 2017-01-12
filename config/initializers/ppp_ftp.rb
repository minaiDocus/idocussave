module PPPFtpConfiguration
  CONFIG       = YAML.load_file("#{Rails.root}/config/ppp_ftp.yml")['ppp_ftp']

  FTP_PATH     = CONFIG['path']
  FTP_SERVER   = CONFIG['server']
  FTP_USERNAME = CONFIG['username']
  FTP_PASSWORD = CONFIG['password']
  FTP_PROVIDER = CONFIG['provider']
end




