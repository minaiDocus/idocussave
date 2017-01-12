class GoogleDrive::Configuration
  attr_accessor :client_id, :client_secret, :scope, :access_type, :approval_prompt, :include_granted_scopes

  def initialize
    @scope                  = 'https://docs.google.com/feeds/ https://docs.googleusercontent.com/'
    @access_type            = 'offline'
    @approval_prompt        = 'auto'
    @include_granted_scopes = false
  end
end
