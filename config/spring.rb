if ENV['RAILS_ENV'] == 'test'
  require 'simplecov'
  SimpleCov.start 'rails' do
    add_group 'Services', 'app/services'
  end
end
