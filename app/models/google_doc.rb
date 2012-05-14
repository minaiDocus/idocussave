class GoogleDoc
  include Mongoid::Document
  include Mongoid::Timestamps
  
  referenced_in :external_file_storage
  
  field :token, :type => String, :default => ""
  field :secret, :type => String, :default => ""
  field :is_configured, :type => Boolean, :default => false
  field :path, :type => String, :default => "iDocus"
  
  def consumer
    @consumer ||= OAuth::Consumer.new( GoogleDocs::CONSUMER_KEY, GoogleDocs::CONSUMER_SECRET, GoogleDocs::SETTINGS )
  end
  
  def get_authorize_url callback
    request_token = consumer.get_request_token( { :oauth_callback => callback }, :scope => GoogleDocs::SCOPE_URL )
    update_attributes(:token => request_token.token, :secret => request_token.secret)
    request_token.authorize_url
  end
  
  def get_access_token verifier
    if !token.empty? and !secret.empty?
      request_token = OAuth::RequestToken.new consumer
      request_token.token = token
      request_token.secret = secret
      access_token = request_token.get_access_token :oauth_verifier => verifier
      update_attributes(:token => access_token.token, :secret => access_token.secret, :is_configured => true)
    else
      raise "Attributes token or/and secret is/are empty."
    end
  end
  
  def access_token
    unless @access_token
      @access_token = OAuth::AccessToken.new consumer
      @access_token.token = token
      @access_token.secret = secret
    end
    @access_token
  end
  
  def is_configured?
    is_configured
  end
  
  def reset_session
    update_attributes(:token => "", :secret => "", :is_configured => false)
  end
  
  def deliver filename, delivery_path
    # TODO implement me
  end
end
