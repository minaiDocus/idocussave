source 'https://rubygems.org'

gem 'rake'
gem 'rails', '5.2.2'


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
gem 'sentry-raven'


# APM
gem 'elastic-apm'


# Image / File processing
gem 'barby'
gem 'prawn'
gem 'paperclip'
gem 'chunky_png'  # required by barby
gem 'haml'
gem 'prawn-qrcode'


# View render and utils
gem 'simple_form'
gem 'nested_form'


# System libraries binding
gem 'gio2'
gem 'poppler'
gem 'gobject-introspection'


# Object renderer
gem 'rabl'


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
gem 'mini_racer'
gem 'uglifier'
gem 'sprockets'
gem 'sprockets-rails'


# CSS Libraries and CSS Processors
gem 'sass-rails'
gem 'compass-rails'
gem 'bootstrap'

# JS Libraries and JS processors
gem 'eco'
gem 'coffee-rails'
gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'backbone-on-rails'


# Frontend tools
gem 'ckeditor'
gem 'bootstrap-datepicker-rails'


# Charts
gem 'd3_rails'


# DB Adapter
gem 'mysql2'


# Scheduling Jobs
gem 'sidekiq'
gem 'sidekiq-scheduler'
gem 'sidekiq-unique-jobs'


# Data format
gem 'oj'
gem 'bson'
gem 'ansi', require: false
gem 'axlsx'
gem 'to_xls'
gem 'hpricot'
gem 'nokogiri'


# External services
gem 'ruby-box'
gem 'dropbox_api'
gem 'google_drive'
gem 'google-api-client'


# Lock mechanism
gem 'remote_lock'

# Encryption
gem 'symmetric-encryption'

# Metric
# gem 'skylight'

gem 'redcarpet'

# Audit
gem 'audited'

gem 'ruby-progressbar', require: false

# Boot
gem 'bootsnap'

group :development, :test do
  gem 'byebug'
  gem 'thin'
  gem 'rspec-rails'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'meta_request'
  gem 'guard-livereload', require: false
  gem 'spring'
  gem 'spring-commands-rspec'
  gem 'libnotify'
  gem 'rack-mini-profiler'
  gem 'rails-i18n'
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
