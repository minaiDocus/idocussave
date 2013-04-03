# -*- encoding : UTF-8 -*-
class GoogleDoc
  include Mongoid::Document
  include Mongoid::Timestamps
  
  belongs_to :external_file_storage
  
  field :token,                type: String,  default: ''
  field :secret,               type: String,  default: ''
  field :is_configured,        type: Boolean, default: false
  field :path,                 type: String,  default: 'iDocus/:code/:year:month/:account_book/'
  field :file_type_to_deliver, type: Integer, default: ExternalFileStorage::PDF

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

  def sync(remote_files)
    remote_files.each_with_index do |remote_file,index|
      remote_path ||= ExternalFileStorage::delivery_path(remote_files.first, self.path)
      tries = 0
      begin
        collection = session.root_collection.find_or_create_subcollections(remote_path)
      rescue => e
        remote_file.not_synced!("[#{e.class}] #{e.message}")
      end
      if collection
        begin
          basename = File.basename(remote_file.local_path, '.*')
          remote_filepath = File.join(remote_path, remote_file.local_name)
          remote_file.sending!(remote_filepath)
          print "\t[#{'%0.3d' % (index+1)}] #{remote_filepath} sending..."
          collection.upload_from_file(remote_file.local_path, basename, { content_type: type_of(remote_file.local_name) })
          remote_file.synced!
          print "done\n"
        rescue => e
          tries += 1
          print " failed : [#{e.class}] #{e.message}\n"
          if tries < 3
            retry
          else
            puts "\t[#{'%0.3d' % (index+1)}] Retrying later"
            remote_file.not_synced!("[#{e.class}] #{e.message}")
          end
        end
      end
    end
  end

  def type_of(filename)
    extension = File.extname(filename)
    case extension
      when '.pdf'
        'application/pdf'
      when '.csv'
        'text/csv'
      else
        'application/pdf'
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
