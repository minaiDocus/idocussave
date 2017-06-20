# -*- encoding : UTF-8 -*-
class Ftp < ActiveRecord::Base
  belongs_to :external_file_storage

  attr_encrypted :host,     random_iv: true
  attr_encrypted :login,    random_iv: true
  attr_encrypted :password, random_iv: true

  scope :configured,     -> { where(is_configured: true) }
  scope :not_configured, -> { where(is_configured: false) }


  validates :login,    length: { minimum: 2, maximum: 40 }, if: proc { |e| e.persisted? }
  validates :password, length: { minimum: 2, maximum: 40 }, if: proc { |e| e.persisted? }
  validates_format_of :host, with: URI.regexp('ftp'),       if: proc { |e| e.persisted? }

  before_create do
    self.host     ||= 'ftp://ftp.example.com'
    self.login    ||= 'login'
    self.password ||= 'password'
  end

  def is_configured?
    is_configured
  end

  def reset_session
    reset_info
    is_configured = false
    save
  end

  def reset_info
    self.host = 'ftp://ftp.example.com'
    self.login = 'login'
    self.password = 'password'
  end

  def verify!
    require "net/ftp"
    begin
      Net::FTP.open(self.host.sub(/\Aftp:\/\//,''),self.login,self.password)
      self.is_configured = true
    rescue Net::FTPPermError, SocketError, Errno::ECONNREFUSED
      self.is_configured = false
      reset_info
    end
    save
    self.is_configured
  end
end
