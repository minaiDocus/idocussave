if ENV['RAILS_ENV'] == 'test' && ENV['SIMPLECOV'] == 'true'
  require 'simplecov'
  SimpleCov.start 'rails' do
    add_group 'Services', 'app/services'
  end
end
