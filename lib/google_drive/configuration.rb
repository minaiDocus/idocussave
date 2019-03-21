class GoogleDrive::Configuration
  attr_accessor :client_id, :client_secret, :scope, :access_type, :approval_prompt, :include_granted_scopes

  def initialize
    @scope                  = 'https://docs.google.com/feeds/ https://docs.googleusercontent.com/'
    @access_type            = 'offline'
    @approval_prompt        = 'auto'
    @include_granted_scopes = false

    @client_id              = Rails.application.credentials[Rails.env.to_sym][:google_drive_api][:client_id]
    @client_secret          = Rails.application.credentials[Rails.env.to_sym][:google_drive_api][:client_secret]

    @scope                  = Rails.application.credentials[Rails.env.to_sym][:google_drive_api][:scope]
    @access_type            = Rails.application.credentials[Rails.env.to_sym][:google_drive_api][:access_type]
    @approval_prompt        = Rails.application.credentials[Rails.env.to_sym][:google_drive_api][:approval_prompt]
    @include_granted_scopes = Rails.application.credentials[Rails.env.to_sym][:google_drive_api][:include_granted_scopes]
  end
end
