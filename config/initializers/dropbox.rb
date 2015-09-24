config_file = File.join(Rails.root, 'config', 'dropbox.yml')
raise 'Dropbox configuration file config/dropbox.yml is missing.' unless File.exist?(config_file)

config = YAML::load_file(config_file)[Rails.env]

Dropbox::APP_KEY = config['app_key']
Dropbox::APP_SECRET = config['app_secret']
Dropbox::ACCESS_TYPE = :app_folder

DropboxExtended::APP_KEY = config['extended_app_key']
DropboxExtended::APP_SECRET = config['extended_app_secret']
DropboxExtended::ACCESS_TYPE = :dropbox
