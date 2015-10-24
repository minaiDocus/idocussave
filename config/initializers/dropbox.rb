config_file = File.join(Rails.root, 'config', 'dropbox.yml')
raise 'Dropbox configuration file config/dropbox.yml is missing.' unless File.exist?(config_file)

config = YAML::load_file(config_file)[Rails.env]

Dropbox::APP_KEY = config['app_key']
Dropbox::APP_SECRET = config['app_secret']
Dropbox::ACCESS_TYPE = :app_folder

Dropbox::EXTENDED_APP_KEY = config['extended_app_key']
Dropbox::EXTENDED_APP_SECRET = config['extended_app_secret']
Dropbox::EXTENDED_ACCESS_TYPE = :dropbox
