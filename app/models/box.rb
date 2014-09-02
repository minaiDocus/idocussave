# -*- encoding : UTF-8 -*-
class Box
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :external_file_storage

  field :access_token
  field :refresh_token
  field :path,                 type: String,  default: ':code/:year:month/:account_book'
  field :is_configured,        type: Boolean, default: false
  field :file_type_to_deliver, type: Integer, default: ExternalFileStorage::PDF

  class << self
    def configure
      yield config
    end

    def config
      @config ||= Configuration.new
    end

    def config=(new_config)
      config.client_id     = new_config['client_id']     if new_config['client_id']
      config.client_secret = new_config['client_secret'] if new_config['client_secret']
      config.callback_url  = new_config['callback_url']  if new_config['callback_url']
    end
  end

  class Configuration
    attr_accessor :client_id, :client_secret, :callback_url
  end

  def session
    if @session
      @session
    else
      options = {
        client_id: Box.config.client_id,
        client_secret: Box.config.client_secret
      }
      options.merge!({ access_token: access_token }) if access_token.present?
      @session = RubyBox::Session.new options
    end
  end

  def get_authorize_url
    session.authorize_url(Box.config.callback_url)
  end

  def get_access_token(code)
    result = session.get_access_token(code)
    @session = nil
    update_attributes(access_token: result.token, refresh_token: result.refresh_token, is_configured: true)
  end

  def client
    @client ||= RubyBox::Client.new(session)
  end

  def is_configured?
    is_configured
  end

  def reset_session
    update_attributes(access_token: nil, refresh_token: nil, is_configured: false)
  end

  def is_up_to_date?(folder, file_name, file_path)
    files = folder.files.select { |e| e.name == file_name }
    if files.any?
      if files.first.size == File.size(file_path)
        true
      else
        false
      end
    else
      nil
    end
  end

  def is_not_up_to_date?(folder, file_name, file_path)
    !is_up_to_date?(folder, file_name, file_path)
  end

  def sync(remote_files)
    remote_files.each_with_index do |remote_file,index|
      remote_path = ExternalFileStorage::delivery_path(remote_file, self.path)
      remote_filepath = File.join(remote_path, remote_file.name)
      tries = 0
      begin
        @folder ||= client.create_folder remote_path
        if @folder
          remote_file.sending!(remote_filepath)
          print "\t[#{'%0.3d' % (index+1)}] \"#{remote_filepath}\" "
          if is_not_up_to_date?(@folder, remote_file.name, remote_file.local_path)
            print "sending..."
            ::File.open(remote_file.local_path, 'rb') do |data|
              @folder.upload_file(remote_file.name, data)
            end
            print "done\n"
          else
            print "is up to date\n"
          end
          remote_file.synced!
        end
      rescue => e
        tries += 1
        print "failed : [#{e.class}] #{e.message}\n"
        if tries < 3
          retry
        else
          puts "\t[#{'%0.3d' % (index+1)}] Retrying later"
          remote_file.not_synced!("[#{e.class}] #{e.message}")
        end
      end
    end
    @folder = nil
  end
end
