config_file = File.join(Rails.root, 'config', 'pdftk.yml')
raise 'Pdftk configuration file config/pdftk.yml is missing.' unless File.exist?(config_file)

Pdftk.config[:exe_path] = YAML.load_file(config_file)['exe_path']
