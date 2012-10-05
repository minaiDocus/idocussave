# -*- encoding : UTF-8 -*-
class GoogleDoc
  include Mongoid::Document
  include Mongoid::Timestamps
  
  referenced_in :external_file_storage
  
  field :token,         type: String,  default: ''
  field :secret,        type: String,  default: ''
  field :is_configured, type: Boolean, default: false
  field :path,          type: String,  default: 'iDocus/:code/:year:month/:account_book/'

  attr_accessor :consumer, :request_token, :access_token, :session

  def session
    @session ||= GoogleDrive.login_with_oauth(get_access_token)
  end

  def consumer
    @consumer ||= OAuth::Consumer.new(GoogleDrive::CONSUMER_KEY, GoogleDrive::CONSUMER_SECRET, GoogleDrive::SETTINGS)
  end

  def get_authorize_url(callback="")
    get_request_token(callback).authorize_url
  end

  def get_access_token(verifier=nil)
    if verifier.present? || (!self.token.present? || !self.secret.present?)
      @access_token = get_request_token.get_access_token oauth_verifier: verifier
      update_attributes(token: access_token.token, secret: access_token.secret, is_configured: true)
    else
      @access_token = OAuth::AccessToken.new(consumer)
      @access_token.token = self.token
      @access_token.secret = self.secret
    end
    @access_token
  end

  def is_configured?
    is_configured
  end
  
  def reset_session
    update_attributes(token: '', secret: '', is_configured: false)
  end

  def deliver(filespath, delivery_path, params={ content_type: 'application/pdf' })
    if session
      clean_path = delivery_path.sub(/\/$/,"")
      collection = session.root_collection.find_or_create_subcollections(clean_path)
      filespath.each do |filepath|
        filename = File.basename(filepath)
        basename = File.basename(filepath,'.*')
        rfilepath = File.join([clean_path,filename])
        tries = 0
        begin
          begin
            print "sending #{rfilepath} ..."
            collection.upload_from_file(filepath,basename, params)
            print "done\n"
          rescue Timeout::Error
            tries += 1
            print "failed\n"
            puts "Trying again!"
            retry if tries < 3
          end
        rescue => e
          Delivery::Error.create(sender: 'GoogleDrive', state: 'sending', filepath: "#{rfilepath}", message: e.message, user_id: user)
        end
      end
    end
  end

  def user
    external_file_storage.user
  end

private

  def get_request_token(callback="")
    if @request_token
      @request_token
    else
      if token.presence && secret.presence
        @request_token = OAuth::RequestToken.new(consumer)
        @request_token.token = self.token
        @request_token.secret = self.secret
      else
        @request_token = consumer.get_request_token( { oauth_callback: callback }, scope: GoogleDrive::SCOPE_URL )
        update_attributes(token: request_token.token, secret: request_token.secret)
      end
      @request_token
    end
  end
end
