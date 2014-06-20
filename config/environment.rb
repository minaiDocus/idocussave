# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
Idocus::Application.initialize!

if Rails.env.production?
  DelayedJobWeb.use Rack::Auth::Basic do |username, password|
    if ENV['IDOCUS_DELAYED_JOB_WEB_PASSWORD'].present?
      username == 'admin' && password == ENV['IDOCUS_DELAYED_JOB_WEB_PASSWORD']
    else
      false
    end
  end
end
