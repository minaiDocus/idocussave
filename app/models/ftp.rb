class Ftp
  include Mongoid::Document
  include Mongoid::Timestamps
  
  referenced_in :external_file_storage
  
  field :host, :type => String, :default => "ftp://ftp.example.com"
  field :login, :type => String, :default => "login"
  field :password, :type => String, :default => "password"
  field :path, :type => String, :default => "iDocus/:code/:year:month/:account_book/"
  field :is_configured, :type => Boolean, :default => false
  
  scope :configured, :where => { :is_configured => true }
  scope :not_configured, :where => { :is_configured => false }
  
  validates_format_of :host, :with => URI::regexp("ftp")
  validates :login, :length => { :minimum => 2, :maximum => 40 }
  validates :password, :length => { :minimum => 2, :maximum => 40 }
  
  def is_configured?
    is_configured
  end
  
  def reset_info
    self.host = "ftp://ftp.example.com"
    self.login = "login"
    self.password = "password"
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
    folders = pathname.split("/")
    folders.each do |folder|
      if ftp.mkdir(folder)
        ftp.chdir(folder)
      else
        raise "Unable to create directory #{folder} in #{pathname}"
      end
    end
  end
  
  def deliver(filesname, folder_path)
    clean_path = folder_path.sub(/\/$/,"")
    
    require "net/ftp"
    
    begin
      Net::FTP.open(host.sub(/^ftp:\/\//,'')) do |ftp|
        ftp.login(login,password)
        change_or_make_dir(clean_path, ftp)
        filesname.each do |filename|
          ftp.put(filename)
        end
        true
      end
    rescue
      false
    end
  end
  
end
