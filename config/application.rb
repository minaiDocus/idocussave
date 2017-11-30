require File.expand_path('../boot', __FILE__)

require 'csv'
require 'rails/all'

Bundler.require(:default, Rails.env)


require 'prawn/measurement_extensions'

module Idocus
  class Application < Rails::Application
    # load all files in lib directory

    # development files
    Dir.glob("#{Rails.root}/app/workers/*.{rb}").each { |file| require file }
    Dir.glob("#{Rails.root}/lib/*.{rb}").each { |file| require file }
    Dir.glob("#{Rails.root}/lib/patches/*.{rb}").each { |file| require file }
    Dir.glob("#{Rails.root}/lib/ibiza_api/*.{rb}").each { |file| require file }
    Dir.glob("#{Rails.root}/lib/knowings_api/*.{rb}").each { |file| require file }
    Dir.glob("#{Rails.root}/lib/google_drive/*.{rb}").each { |file| require file }

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]

    I18n.config.enforce_available_locales = false
    config.i18n.locale = :fr
    config.i18n.default_locale = :fr


    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = 'utf-8'


    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [
      :password,
      :rawScan,
      :improvedScan,
      :param1,
      :param2,
      :param3,
      :param4,
      :param5,
      :answers,
      :access_token,
      :token,
      :connections # Budgea webhooks param
    ]


    config.generators do |g|
      g.template_engine :haml
      g.test_framework :rspec, fixture: true, views: false
      g.fixture_replacement :factory_girl, dir: 'spec/factories'
    end


    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '1.0'


    config.wash_out.parser = :nokogiri
    config.wash_out.camelize_wsdl = true
    config.wash_out.namespace = 'http://service.operator.dematbox.sagemcom.com/'


    config.active_job.queue_adapter = :sidekiq


    config.autoload_paths += %W(
      #{config.root}/app/workers
      #{config.root}/app/services
      #{config.root}/app/mailers
    )

    config.eager_load_paths += %W(
      #{config.root}/app/workers
      #{config.root}/app/services
      #{config.root}/app/mailers
    )


    Paperclip.options[:log] = false


    ActionMailer::Base.default from: 'iDocus <notification@idocus.com>', reply_to: 'Support iDocus <support@idocus.com>'

    config.middleware.swap Rails::Rack::Logger, CustomLogger, alternative: ['/account/notifications/latest']
  end
end
