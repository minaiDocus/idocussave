# -*- encoding : UTF-8 -*-
require 'rubygems'
require 'spork'

Spork.prefork do
  unless ENV['DRB']
    require 'simplecov'
    SimpleCov.start 'rails'
  end

  # Loading more in this block will cause your tests to run faster. However,
  # if you change any configuration or code from libraries loaded here, you'll
  # need to restart spork for it take effect.
  
  # This file is copied to spec/ when you run 'rails generate rspec:install'
  ENV["RAILS_ENV"] ||= 'test'

  # Set webmock, that is used by vcr, to allow net connections BEFORE we require the environment file
  require 'webmock'

  require File.expand_path("../../config/environment", __FILE__)
  require 'rspec/rails'
  require 'capybara/rails'
  require 'capybara/rspec'

  # Requires supporting ruby files with custom matchers and macros, etc,
  # in spec/support/ and its subdirectories.
  Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

  counter = -1
  RSpec.configure do |config|
    config.pattern = "**/*_spec.rb"
    
    # == Mock Framework
    #
    # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
    #
    # config.mock_with :mocha
    # config.mock_with :flexmock
    # config.mock_with :rr
    config.mock_with :rspec
    
    # If you're not using ActiveRecord, or you'd prefer not to run each of your
    # examples within a transaction, comment the following line or assign false
    # instead of true.
    # config.use_transactional_fixtures = false

    config.treat_symbols_as_metadata_keys_with_true_values = true
    config.around(:each, :vcr) do |example|
      name = example.metadata[:full_description].split(/\s+/, 2).join("/").underscore.gsub(/[^\w\/]+/, "_")
      options = example.metadata.slice(:record, :match_requests_on).except(:example_group)
      VCR.use_cassette(name, options) { example.call }
    end
    
    config.before(:suite) do
      DatabaseCleaner.orm = "mongoid"
      DatabaseCleaner.strategy = :truncation
      DatabaseCleaner.clean_with(:truncation)
    end
    
    config.before(:all) do
      DatabaseCleaner.start
    end

    config.after(:all) do
      DatabaseCleaner.clean
    end
    
    config.after(:each) do
      counter += 1
      if counter > 9
        GC.enable
        GC.start
        GC.disable
        counter = 0
      end
    end

    config.after(:suite) do
      counter = 0
    end

    config.include Capybara::DSL
    config.include Mongoid::Matchers
    config.include FactoryGirl::Syntax::Methods
    config.extend LoginMacros
    config.include Devise::TestHelpers, :type => :controller
  end
end

Spork.each_run do
  GC.disable

  if ENV['DRB']
    require 'simplecov'
    SimpleCov.start 'rails'
  end

  # This code will be run each time you run your specs.
  module Kernel
    def suppress_warnings
      original_verbosity = $VERBOSE
      $VERBOSE = nil
      result = yield
      $VERBOSE = original_verbosity
      return result
    end
  end

  suppress_warnings do
    FactoryGirl.reload
    Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| load f}
    load 'Sporkfile.rb' if File.exist? 'Sporkfile.rb'
  end
end
