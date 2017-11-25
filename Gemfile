source 'http://rubygems.org'

gem 'rake'
gem 'rails', '4.2.7.1'


# Object state management
gem 'state_machines-activerecord'


# XML-RPC/SOAP
gem 'savon'
gem 'wash_out', git: 'git@github.com:Pikomu/wash_out.git', branch: 'removing_model_integration'


# Pagination
gem 'kaminari'


# Authentication
gem 'oauth'
gem 'devise'


# Error handling
gem 'airbrake', '4.3.8'


# Image / File processing
gem 'barby'
gem 'prawn', '1.0.0rc1'
gem 'paperclip', '~> 4.2.2'
gem 'chunky_png'  # required by barby
gem 'haml'
gem 'prawn-qrcode'


# View render and utils
gem 'simple_form'
gem 'nested_form'


# System libraries binding
gem 'gio2'
gem 'poppler'
gem 'gobject-introspection', '~> 3.0.0'


# Object renderer
gem 'rabl', '0.11.6'


# Query & Network management
gem 'net-sftp'
gem 'typhoeus'


# Cache
gem 'dalli'


# Deployment
gem 'capistrano'
gem 'capistrano-rvm'
gem 'capistrano-rails'
gem 'capistrano_colors', require: false


# Validators
gem 'validate_url'


# Processes management
gem 'posix-spawn'


# Console tools
gem 'hirb', require: false


# Assets management
gem 'therubyracer'
gem 'uglifier', '>= 1.3.0'
gem 'sprockets', '2.12.3'
gem 'sprockets-rails', '2.3.1'


# CSS Libraries and CSS Processors
gem 'sass-rails', '4.0.5'
gem 'compass-rails'
gem 'bootstrap-sass', '2.0.4.2'


# JS Libraries and JS processors
gem 'eco'
gem 'coffee-rails'
gem 'jquery-rails', '2.0.2'
gem 'jquery-ui-rails', '1.1.0'
gem 'backbone-on-rails', '0.9.9.0'


# Frontend tools
gem 'ckeditor'
gem 'bootstrap-datepicker-rails'


# Charts
gem 'd3_rails'


# DB Adapter
gem 'mysql2'


# Scheduling Jobs
gem 'sidekiq'
gem 'sidekiq-scheduler', '~> 2.0'
gem 'sidekiq-unique-jobs'


# Data format
gem 'oj'
gem 'bson'
gem 'ansi', require: false
gem 'axlsx'
gem 'to_xls'
gem 'hpricot'
gem 'nokogiri', '~> 1.7'


# External services
gem 'ruby-box'
gem 'dropbox_api'
gem 'google_drive', '1.0.1'
gem 'google-api-client', '0.8.2'


# Lock mechanism
gem 'remote_lock'

# Encryption
gem 'symmetric-encryption'

# Metric
# gem 'skylight'

gem 'redcarpet'

# Audit
gem 'audited', '~> 4.5'

group :development, :test do
  gem 'byebug'
  gem 'thin'
  gem 'rspec-rails'
  gem 'quiet_assets'
  gem 'better_errors', '1.1.0'
  gem 'binding_of_caller'
  gem 'meta_request'
  gem 'guard-livereload', require: false
  gem 'spring'
  gem 'spring-commands-rspec'
  gem 'libnotify'
  gem 'rack-mini-profiler'
end

group :test do
  gem 'factory_girl_rails'
  gem 'simplecov', require: false
  gem 'capybara'
  gem 'guard-rspec', require: false
  gem 'database_cleaner'
  gem 'timecop'
  gem 'vcr'
  gem 'webmock'
  gem 'ftpd', require: false
end
