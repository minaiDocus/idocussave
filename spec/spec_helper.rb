# -*- encoding : UTF-8 -*-
require 'rubygems'

# Name the report with pid of spring fork for merging purpose
SimpleCov.command_name "##{$$}" if defined?(SimpleCov)

ENV["RAILS_ENV"] ||= 'test'

# Set webmock, that is used by vcr, to allow net connections BEFORE we require the environment file
require 'webmock'
require 'webmock/rspec'

require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'capybara/rails'
require 'capybara/rspec'

require 'sidekiq/testing'
# Sidekiq::Testing.inline! #execute jobs immediatly

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

module Kernel
  def suppress_warnings
    original_verbosity = $VERBOSE
    $VERBOSE = nil
    result = yield
    $VERBOSE = original_verbosity
    return result
  end
end

RSpec.configure do |config|
  config.pattern = "**/*_spec.rb"

  # == Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr

  config.use_transactional_fixtures = false
  
  config.mock_with :rspec

  config.infer_spec_type_from_file_location!
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true

  # FactoryGirl.allow_class_lookup = false

  config.around(:each, :vcr) do |example|
    name = example.metadata[:full_description].split(/\s+/, 2).join("/").underscore.gsub(/[^\w\/]+/, "_")
    options = example.metadata.slice(:record, :match_requests_on).except(:example_group)
    VCR.use_cassette(name, options) { example.call }
  end

  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)

    begin
      DatabaseCleaner.start
      FactoryBot.lint
    ensure
      DatabaseCleaner.clean
    end

    suppress_warnings do
      FactoryBot.reload
      Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| load f}
    end
  end

  # config.before(:each) do
  #   Sidekiq::Worker.clear_all
  # end

  config.before(:all) do
    DatabaseCleaner.start
  end

  config.after(:all) do
    DatabaseCleaner.clean
  end

  config.include Capybara::DSL
  config.include FactoryBot::Syntax::Methods
  config.extend LoginMacros
  config.include Devise::Test::ControllerHelpers, :type => :controller
end