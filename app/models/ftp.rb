# -*- encoding : UTF-8 -*-
require "net/ftp"

class Ftp
  include Mongoid::Document
  include Mongoid::Timestamps
  
  referenced_in :external_file_storage
  
  field :host,          type: String,  default: 'ftp://ftp.example.com'
  field :login,         type: String,  default: 'login'
  field :password,      type: String,  default: 'password'
  field :path,          type: String,  default: 'iDocus/:code/:year:month/:account_book/'
  field :is_configured, type: Boolean, default: false
  
  scope :configured,     where: { is_configured: true }
  scope :not_configured, where: { is_configured: false }
  
  validates_format_of :host, with: URI::regexp("ftp")
  validates :login,    length: { minimum: 2, maximum: 40 }
  validates :password, length: { minimum: 2, maximum: 40 }

  def client
    if is_configured?
      @ftp ||= Net::FTP.new(host.sub(/^ftp:\/\//,''), login, password)
    else
      nil
    end
  end
  
  def is_configured?
    is_configured
  end
  
  def reset_info
    self.host = 'ftp://ftp.example.com'
    self.login = 'login'
    self.password = 'password'
  end
  
  def verify!
    require "net/ftp"
    begin
      Net::FTP.open(self.host.sub(/^ftp:\/\//,''),self.login,self.password)
      self.is_configured = true
    rescue Net::FTPPermError, SocketError
      self.is_configured = false
      reset_info
    end
    save
    self.is_configured
  end
  
  def change_or_make_dir(pathname)
    folders = pathname.split("/").reject { |e| e.empty? }
    folders.each do |folder|
      client.mkdir(folder) rescue nil
      client.chdir(folder)
    end
  end
  
  def is_updated(filepath)
    filename = File.basename(filepath)
    result = client.list.select { |entry| entry.match(/#{filename}/) }.first
    if result
      size = result.split(/\s/).reject(&:empty?)[4].to_i rescue 0
      if size == File.size(filepath)
        true
      else
        false
      end
    else
      false
    end
  end
  
  def is_not_updated(filepath)
    !is_updated(filepath)
  end

  def sync(remote_files)
    remote_files.each_with_index do |remote_file,index|
      remote_path ||= ExternalFileStorage::delivery_path(remote_files.first, self.path)
      is_ok = true
      begin
        change_or_make_dir(remote_path)
      rescue => e
        is_ok = false
        remote_file.not_synced!("[#{e.class}] #{e.message}")
      end
      if is_ok
        remote_filepath = File.join(remote_path,remote_file.local_name)
        tries = 0
        begin
          remote_file.sending!(remote_filepath)
          print "\t[#{'%0.3d' % (index+1)}] \"#{remote_filepath}\" "
          if is_not_updated(remote_file.local_path)
            print "sending..."
            client.put(remote_file.local_path)
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
  end
end
