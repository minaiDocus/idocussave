class GoogleDoc
  include Mongoid::Document
  include Mongoid::Timestamps
  
  referenced_in :external_file_storage
  
  field :token, :type => String, :default => ""
  field :secret, :type => String, :default => ""
  field :is_configured, :type => Boolean, :default => false
  field :path, :type => String, :default => "iDocus/:code/:year:month/:account_book/"
  
  attr_accessor :service
  
  def get_authorize_url(callback)
    request_token = service.get_request_token(callback)
    update_attributes(:token => request_token.token, :secret => request_token.secret)
    request_token.authorize_url
  end
  
  def get_access_token(verifier)
    if !token.empty? and !secret.empty?
      access_token = service.get_access_token(verifier)
      update_attributes(:token => access_token.token, :secret => access_token.secret, :is_configured => true)
      access_token
    else
      raise "Attributes token or/and secret is/are empty."
    end
  end
  
  def service
    if !self.token.empty? and !self.secret.empty?
      @service ||= GoogleDocumentsList::API::Service.new(self.token, self.secret)
    else
      @service ||= GoogleDocumentsList::API::Service.new()
    end
  end
  
  def is_configured?
    is_configured
  end
  
  def reset_session
    update_attributes(:token => "", :secret => "", :is_configured => false)
  end
  
  def deliver(filespath, delivery_path)
    if service
      collection = service.get_collection_id(delivery_path)
      if collection
        colID = collection["id"]
        filespath.each do |filepath|
          service.upload_file(filepath, colID, "text/plain")
        end
      end
    end
  end
end
