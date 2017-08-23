class Ftp < ActiveRecord::Base
  belongs_to :external_file_storage

  attr_encrypted :host,     random_iv: true
  attr_encrypted :port,     random_iv: true, type: :integer
  attr_encrypted :login,    random_iv: true
  attr_encrypted :password, random_iv: true

  scope :configured,     -> { where(is_configured: true) }
  scope :not_configured, -> { where(is_configured: false) }

  validates :login,    length: { minimum: 2, maximum: 40 }, if: proc { |e| e.persisted? }
  validates :password, length: { minimum: 2, maximum: 40 }, if: proc { |e| e.persisted? }
  validates_format_of :host, with: /\Aftp:\/\/(([a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5})|localhost)(\/)?\z/ix, if: proc { |e| e.persisted? }
  validates_numericality_of :port, greater_than: 0, less_than: 65536, if: proc { |e| e.persisted? }

  before_create do
    self.host     ||= 'ftp://ftp.example.com'
    self.port     ||= 21
    self.login    ||= 'login'
    self.password ||= 'password'
  end

  def is_configured?
    is_configured
  end

  def reset_info
    self.host          = 'ftp://ftp.example.com'
    self.port          = 21
    self.login         = 'login'
    self.password      = 'password'
    self.is_passive    = true
    self.is_configured = false
    save
  end

  def domain
    host.sub /\Aftp:\/\//, ''
  end
end
