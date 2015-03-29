config_file = File.join(Rails.root, 'config', 'google_drive.yml')
raise 'Google Drive configuration file config/google_drive.yml is missing.' unless File.exists?(config_file)

GoogleDrive.config = YAML::load_file(config_file)[Rails.env]
