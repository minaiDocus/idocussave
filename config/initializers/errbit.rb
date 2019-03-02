#require 'airbrake/rake_handler'

# Airbrake.configure do |config|
#   config.api_key = Rails.application.secrets.errbit_api_key
#   config.host    = 'errbit.idocus.com'
#   config.port    = 443
#   config.secure  = config.port == 443
#   config.rescue_rake_exceptions = true
#   config.ignore << ['ActionController::UnknownController']
#   config.user_attributes = %w(id username)
# end
