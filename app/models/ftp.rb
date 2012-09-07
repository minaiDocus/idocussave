# -*- encoding : UTF-8 -*-
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
      Net::FTP.new(host.sub(/^ftp:\/\//,''), login, password)
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
  
  def change_or_make_dir(pathname, ftp)
    folders = pathname.split("/").reject { |e| e.empty? }
    folders.each do |folder|
      ftp.mkdir(folder) rescue nil
      ftp.chdir(folder)
    end
  end
  
  def is_updated(filepath, ftp)
    result = ftp.list.select { |entry| entry.match(/#{filename}/) }.first
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
  
  def is_not_updated(filepath, ftp)
    !is_updated(filepath, ftp)
  end
  
  def deliver(filespath, folder_path)
    clean_path = folder_path.sub(/\/$/,"")
    
    require "net/ftp"
    
    begin
      Net::FTP.open(host.sub(/^ftp:\/\//,'')) do |ftp|
        ftp.login(login,password)
        change_or_make_dir(clean_path, ftp)
        filespath.each do |filepath|
          filename = File.basename(filepath)
          if is_not_updated(filepath, ftp)
            ftp.put(filepath)
          end
        end
        true
      end
    rescue => e
      Delivery::Error.create(sender: 'FTP', state: 'sending', filepath: "#{clean_path}/#{filename}", message: e)
      false
    end
  end
end
