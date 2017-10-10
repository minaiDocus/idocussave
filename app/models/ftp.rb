class Ftp < ActiveRecord::Base
  belongs_to :organization
  belongs_to :external_file_storage

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
  validates_format_of :host, with: /\Aftp:\/\/(([a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5})|localhost)(\/)?\z/ix, if: proc { |e| e.persisted? }
  validates_numericality_of :port, greater_than: 0, less_than: 65536, if: proc { |e| e.persisted? }
  validate :uniqueness_of_path

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

  private

  def uniqueness_of_path
    if organization && path.match(/\A(\/)*INPUT(\/)*/)
      errors.add(:path, :invalid)
    end
  end
end
