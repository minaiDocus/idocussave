require_relative 'boot'

require 'csv'
require 'rails/all'

Bundler.require(:default, Rails.env)


require 'prawn/measurement_extensions'

module Idocus
  class Application < Rails::Application
    # load all files in lib directory

    config.load_defaults 5.2

    # development files
    Dir.glob("#{Rails.root}/app/interfaces/interfaces.rb").each { |file| require file }
    Dir.glob("#{Rails.root}/lib/api_broker/*.{rb}").each { |file| require file }
    Dir.glob("#{Rails.root}/app/workers/*.{rb}").each { |file| require file }
    Dir.glob("#{Rails.root}/lib/*.{rb}").each { |file| require file }
    Dir.glob("#{Rails.root}/lib/patches/*.{rb}").each { |file| require file }
    Dir.glob("#{Rails.root}/lib/knowings_api/*.{rb}").each { |file| require file }
    Dir.glob("#{Rails.root}/lib/google_drive/*.{rb}").each { |file| require file }
    Dir.glob("#{Rails.root}/lib/supplier_recognition/*.{rb}").each { |file| require file }
    Dir.glob("#{Rails.root}/lib/jefacture/*.{rb}").each { |file| require file }
    Dir.glob("#{Rails.root}/lib/ibiza_lib/api/*.{rb}").each { |file| require file }
    Dir.glob("#{Rails.root}/lib/ibiza_lib/*.{rb}").each { |file| require file }
    Dir.glob("#{Rails.root}/lib/my_unisoft_lib/*.{rb}").each { |file| require file }
    Dir.glob("#{Rails.root}/lib/my_unisoft_lib/api/*.{rb}").each { |file| require file }
    Dir.glob("#{Rails.root}/lib/exact_online_lib/api/*.{rb}").each { |file| require file }
    Dir.glob("#{Rails.root}/lib/exact_online_lib/*.{rb}").each { |file| require file }
    Dir.glob("#{Rails.root}/lib/mcf_lib/api/*.{rb}").each { |file| require file }
    Dir.glob("#{Rails.root}/lib/mcf_lib/*.{rb}").each { |file| require file }

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = 'Europe/Paris'

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
      :connections, # Budgea webhooks param
      :expiration_date,
      :ByteResponse # MCF file uploaded byte code
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
      #{config.root}/app/models/ckeditor
    )

    config.eager_load_paths += %W(
      #{config.root}/app/workers
      #{config.root}/app/services
      #{config.root}/app/mailers
      #{config.root}/app/models/ckeditor
    )


    Paperclip.options[:log] = false


    ActionMailer::Base.default from: 'iDocus <notification@idocus.com>', reply_to: 'Support iDocus <support@idocus.com>'

    Raven.configure do |config|
      config.dsn = 'https://8a88cb7b80654dc5bd2bc9bfd8b160a0:b79bb42c43bc4c918442ebd04f5f61b9@sentry.idocus.com/2'
      config.environments = ['sandbox', 'staging', 'production']
    end
  end
end
