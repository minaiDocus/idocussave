# -*- encoding : UTF-8 -*-
module GoogleDrive
  class << self
    attr_reader :config

    def configure
      yield config
    end

    def config
      @config ||= Configuration.new
    end

    def config=(new_config)
      config.client_id              = new_config['client_id']              if new_config['client_id']
      config.client_secret          = new_config['client_secret']          if new_config['client_secret']
      config.scope                  = new_config['scope']                  if new_config['scope']
      config.access_type            = new_config['access_type']            if new_config['access_type']
      config.approval_prompt        = new_config['approval_prompt']        if new_config['approval_prompt']
      config.include_granted_scopes = new_config['include_granted_scopes'] if new_config['include_granted_scopes']
    end
  end

  class Configuration
    attr_accessor :client_id, :client_secret, :scope, :access_type, :approval_prompt, :include_granted_scopes

    def initialize
      @scope                  = 'https://docs.google.com/feeds/ https://docs.googleusercontent.com/'
      @access_type            = 'offline'
      @approval_prompt        = 'auto'
      @include_granted_scopes = false
    end
  end

  class Client
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

    def authorize_url(redirect_uri, state=nil)
      @client.auth_code.authorize_url(
        response_type:          'code',
        redirect_uri:           redirect_uri,
        scope:                  @config.scope,
        state:                  state,
        access_type:            @config.access_type,
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

  class Collection
    def upload_from_file(path, title,params = {})
      find_and_remove_files(title)
      file = @session.upload_from_file(path, title, params)
      unless root?
        add file
        @session.root_collection.remove file
      end
      file
    end

    def find_or_create_subcollections(path)
      dirs = path.split('/').select { |e| e.present? }
      current_collection = self
      dirs.each do |dir|
        collection = current_collection.subcollection_by_title(dir)
        if collection
          current_collection = collection
        else
          current_collection = current_collection.create_subcollection(dir)
        end
      end
      current_collection
    end

    def find_and_remove_files(title)
      files.each do |file|
        file.delete if file.title == title
      end
    end
  end
end
