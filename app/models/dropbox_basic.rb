# -*- encoding : UTF-8 -*-
class DropboxBasic
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :external_file_storage

  field :access_token
  field :path,                 type: String,  default: ':code/:year:month/:account_book/'

  field :dropbox_id,          type: Integer
  field :changed_at,          type: Time
  field :checked_at,          type: Time
  field :delta_cursor,        type: String
  field :delta_path_prefix,   type: String
  field :import_folder_paths, type: Array, default: []

  validate :beginning_of_path

  before_destroy do
    self.class.disable_access_token(self.access_token) if self.access_token.present?
  end

  class << self
    def disable_access_token(access_token)
      client = DropboxClient.new(access_token, Dropbox::ACCESS_TYPE)
      client.disable_access_token
    end
    handle_asynchronously :disable_access_token, priority: 5
  end

  def user
    external_file_storage.user
  end

  def is_configured?
    access_token.present?
  end

  def is_used?
    external_file_storage.is_used?(ExternalFileStorage::F_DROPBOX)
  end

  def client
    if is_configured?
      @client ||= DropboxClient.new(access_token, Dropbox::ACCESS_TYPE)
    else
      nil
    end
  end

  def is_up_to_date(remote_filepath, filepath)
    path = File.dirname(remote_filepath)
    filename = File.basename(remote_filepath)
    results = client.search(path, filename, 1)
    if results.any?
      size = results.first["bytes"]
      if size == File.size(filepath)
        true
      else
        false
      end
    else
      nil
    end
  end

  def is_not_up_to_date(remote_filepath, filepath)
    !is_up_to_date(remote_filepath, filepath)
  end

  def sync(remote_files)
    remote_files.each_with_index do |remote_file,index|
      remote_path = ExternalFileStorage::delivery_path(remote_file, self.path)
      remote_filepath = File.join(remote_path, remote_file.name)
      tries = 0
      begin
        remote_file.sending!(remote_filepath)
        print "\t[#{'%0.3d' % (index+1)}] \"#{remote_filepath}\" "
        if is_not_up_to_date(remote_filepath, remote_file.local_path)
          print "sending..."
          client.put_file("#{remote_filepath}", open(remote_file.local_path), true)
          print "done\n"
        else
          print "is up to date\n"
        end
        remote_file.synced!
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
  end

private

  def beginning_of_path
    if path.match /\A\/*exportation vers iDocus/
      errors.add(:path, :invalid)
    end
  end
end
