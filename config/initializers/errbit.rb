Airbrake.configure do |config|
  config.api_key = 'api_key'
  config.host    = 'errbit.idocus.com'
  config.port    = 443
  config.secure  = config.port == 443
  config.rescue_rake_exceptions = true
  config.ignore << ["ActionController::UnknownController", "BSON::InvalidObjectId", "Mongoid::Errors::DocumentNotFound"]
  config.user_attributes = ['id', 'username']
  config.async do |notice|
    Airbrake.sender.delay.send_to_airbrake(notice.to_xml)
  end
end
