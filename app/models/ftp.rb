class Ftp < ApplicationRecord
  belongs_to :organization, optional: true
  belongs_to :external_file_storage, optional: true

  attr_encrypted :host,     random_iv: true
  attr_encrypted :port,     random_iv: true, type: :integer
  attr_encrypted :login,    random_iv: true
  attr_encrypted :password, random_iv: true

  serialize :previous_import_paths, Array

  scope :configured,       -> { where(is_configured: true) }
  scope :not_configured,   -> { where(is_configured: false) }
  scope :for_organization, -> { where.not(organization_id: nil) }
  scope :importable,       -> { for_organization.configured }

  validates :login,    length: { minimum: 2, maximum: 40 }, if: proc { |e| e.persisted? }
  validates :password, length: { minimum: 2, maximum: 40 }, if: proc { |e| e.persisted? }
  validates_numericality_of :port, greater_than: 0, less_than: 65536, if: proc { |e| e.persisted? }
  validate :uniqueness_of_path
  validate :host_format, if: proc { |e| e.persisted? }

  before_create do
    self.host     ||= 'ftp://ftp.example.com'
    self.port     ||= 21
    self.login    ||= 'login'
    self.password ||= 'password'
  end

  def user
    external_file_storage.try(:user)
  end

  def configured?
    is_configured
  end

  def used?
    external_file_storage ? external_file_storage.is_used?(ExternalFileStorage::F_FTP) : true
  end

  def enable
    external_file_storage ? external_file_storage.use(ExternalFileStorage::F_FTP) : false
  end

  def disable
    external_file_storage ? external_file_storage.unuse(ExternalFileStorage::F_FTP) : false
  end

  def reset_info
    self.host          = 'ftp://ftp.example.com'
    self.port          = 21
    self.login         = 'login'
    self.password      = 'password'
    self.root_path     = '/'
    if self.organization
      self.path        = 'OUTPUT/:code/:year:month/:account_book/'
    else
      self.path        = 'iDocus/:code/:year:month/:account_book/'
    end
    self.is_passive    = true
    self.is_configured = false
    save
  end

  def domain
    host.sub /\Aftp:\/\//, ''
  end

  def got_error(message, deactivate=false)
   update({ error_message: message, error_fetched_at: Time.now })

    if deactivate
      self.is_configured = false
      save
    end
  end

  def clean_error
    update({ error_message: nil, error_fetched_at: nil })
  end

  private

  def host_format
    #host valid for :
    #ftp host format : ex : ftp://ftp.example.com
    #ipv4 format : ex : 192.168.0.1
    valid_format = host.match(/\Aftp:\/\/(([a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5})|localhost)(\/)?\z/ix) ||
                   host.match(/^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/)
    errors.add(:host, :invalid) unless valid_format
  end

  def uniqueness_of_path
    if organization && path.match(/\A(\/)*INPUT(\/)*/)
      errors.add(:path, :invalid)
    end
  end
end
