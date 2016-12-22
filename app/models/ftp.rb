# -*- encoding : UTF-8 -*-
class Ftp < ActiveRecord::Base
  belongs_to :external_file_storage


  scope :configured,     -> { where(is_configured: true) }
  scope :not_configured, -> { where(is_configured: false) }


  validates :login,    length: { minimum: 2, maximum: 40 }
  validates :password, length: { minimum: 2, maximum: 40 }
  validates_format_of :host, with: URI.regexp('ftp')
end
