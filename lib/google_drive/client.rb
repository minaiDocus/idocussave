class GoogleDrive::Client
  attr_reader :config, :client, :access_token

  def initialize
    @config = GoogleDrive.config.dup

    @client = OAuth2::Client.new(
      @config.client_id,
      @config.client_secret,
      site: 'https://accounts.google.com',
      token_url: '/o/oauth2/token',
      authorize_url: '/o/oauth2/auth'
    )
  end


  def authorize_url(redirect_uri, state = nil)
    @client.auth_code.authorize_url(
      scope:                  @config.scope,
      state:                  state,
      access_type:            @config.access_type,
      redirect_uri:           redirect_uri,
      response_type:          'code',
      approval_prompt:        @config.approval_prompt,
      include_granted_scopes: @config.include_granted_scopes
    )
  end


  def authorize(code, redirect_uri)
    @access_token = @client.auth_code.get_token(code, redirect_uri: redirect_uri)
  end


  def session
    GoogleDrive.login_with_oauth(@access_token) if @access_token
  end


  def load_session(token)
    @access_token = OAuth2::AccessToken.from_hash(@client, access_token: token)
    session
  end


  def new_session(refresh_token)
    @access_token = OAuth2::AccessToken.from_hash(@client,
                                                  refresh_token: refresh_token,
                                                  expires_at: 1.hour.from_now
                                                 )

    @access_token = @access_token.refresh!

    session
  end
end
