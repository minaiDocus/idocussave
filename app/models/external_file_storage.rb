# -*- encoding : UTF-8 -*-
class ExternalFileStorage
  include Mongoid::Document
  include Mongoid::Timestamps
  
  SERVICES = ["Dropbox", "Dropbox Extended", "Google Drive", "FTP", "Box", "Knowings"]
  
  F_DROPBOX     = 2
  F_GOOGLE_DOCS = 4
  F_FTP         = 8
  F_BOX         = 16

  ALL_TYPES = 1
  PDF       = 2
  TIFF      = 3
  
  belongs_to :user
  has_one :dropbox_basic, autosave: true
  has_one :google_doc,    autosave: true
  has_one :ftp,           autosave: true
  has_one :box,           autosave: true

  accepts_nested_attributes_for :dropbox_basic, :google_doc, :ftp, :box

  field :path,         type: String,  default: 'iDocus/:code/:year:month/:account_book/'
  field :is_path_used, type: Boolean, default: false
  field :used,         type: Integer, default: 0
  field :authorized,   type: Integer, default: 30

  after_create :init_services
  
  def authorize(flags)
    update_attributes(authorized: authorized | flags)
  end
  
  def unauthorize(flags)
    update_attributes(authorized: authorized ^ ( authorized & flags))
  end
  
  def is_dropbox_basic_authorized?
    authorized & F_DROPBOX > 0
  end

  def is_dropbox_basic_authorized
    is_dropbox_basic_authorized?
  end

  def is_dropbox_basic_authorized=(value)
    ok = value.to_i == 1
    self.authorized = ok ? self.authorized | F_DROPBOX : self.authorized ^ F_DROPBOX
  end
  
  def is_google_docs_authorized?
    authorized & F_GOOGLE_DOCS > 0
  end

  def is_google_docs_authorized
    is_google_docs_authorized?
  end

  def is_google_docs_authorized=(value)
    ok = value.to_i == 1
    self.authorized = ok ? self.authorized | F_GOOGLE_DOCS : self.authorized ^ F_GOOGLE_DOCS
  end
  
  def is_ftp_authorized?
    authorized & F_FTP > 0
  end

  def is_ftp_authorized
    is_ftp_authorized?
  end

  def is_ftp_authorized=(value)
    ok = value.to_i == 1
    self.authorized = ok ? self.authorized | F_FTP : self.authorized ^ F_FTP
  end
  
  def is_box_authorized?
    authorized & F_BOX > 0
  end
  
  def is_box_authorized
    is_box_authorized?
  end
  
  def is_box_authorized=(value)
    ok = value.to_i == 1
    self.authorized = ok ? self.authorized | F_BOX : self.authorized ^ F_BOX
  end
  
  def is_authorized?(flag)
    authorized & flag > 0
  end
  
  def services_authorized
    services  = []
    services << "Dropbox"          if authorized & F_DROPBOX > 0
    services << "Dropbox Extended" if user.is_dropbox_extended_authorized
    services << "Google Drive"     if authorized & F_GOOGLE_DOCS > 0
    services << "FTP"              if authorized & F_FTP > 0
    services << "Box"              if authorized & F_BOX > 0
    services.join(", ")
  end
  
  def services_authorized_count
    nb = 0
    nb += 1 if authorized & F_DROPBOX > 0
    nb += 1 if user.is_dropbox_extended_authorized
    nb += 1 if authorized & F_GOOGLE_DOCS > 0
    nb += 1 if authorized & F_FTP > 0
    nb += 1 if authorized & F_BOX > 0
    nb
  end
  
  def use(flags)
    trusted_flags = authorized & flags
    if trusted_flags == flags and services_used_count < 2
      update_attributes(used: used | trusted_flags)
    else
      false
    end
  end
  
  def unuse(flags)
    update_attributes(used: used ^ ( used & flags ))
  end
  
  def is_used?(flag)
    used & flag > 0
  end
  
  def services_used
    active_services_name.join(", ")
  end
  
  def services_used_count
    nb = 0
    nb += 1 if used & F_DROPBOX > 0
    nb += 1 if used & F_GOOGLE_DOCS > 0
    nb += 1 if used & F_FTP > 0
    nb += 1 if used & F_BOX > 0
    nb
  end

  def active_services_name
    services  = []
    services << "Dropbox"          if (authorized & used & F_DROPBOX     > 0) && dropbox_basic.is_configured?
    services << "Dropbox Extended" if user.is_dropbox_extended_authorized
    services << "Google Drive"     if (authorized & used & F_GOOGLE_DOCS > 0) && google_doc.is_configured?
    services << "FTP"              if (authorized & used & F_FTP         > 0) && ftp.is_configured?
    services << "Box"              if (authorized & used & F_BOX         > 0) && box.is_configured?
    services
  end

  def dropbox_extended
    DropboxExtended if user.is_dropbox_extended_authorized
  end

  def self.static_path(path, info_path)
    path.gsub(":code",           info_path[:code]).
    gsub(":customer_code",       info_path[:customer_code]).
    gsub(":organization_code",   info_path[:organization_code] || '').
    gsub(":company",             info_path[:company] || '').
    gsub(":group",               info_path[:group] || '').
    gsub(":company_of_customer", info_path[:company_of_customer]).
    gsub(":account_book",        info_path[:account_book]).
    gsub(":year",                info_path[:year]).
    gsub(":month",               info_path[:month]).
    gsub(":delivery_date",       info_path[:delivery_date]).
    split('/').select(&:present?).join('/')
  end

  def self.delivery_path(remote_file, pseudo_path)
    info_path = Pack.info_path(remote_file.pack_name,remote_file.receiver)
    static_path(pseudo_path.sub(/\/$/,""),info_path)
  end

  def get_service_by_name(name)
    case name
      when "Dropbox"
        dropbox_basic
      when "Dropbox Extended"
        DropboxExtended
      when "Google Drive"
        google_doc
      when "FTP"
        ftp
      when "Box"
        box
      else
        nil
    end
  end

  protected

  def init_services
    DropboxBasic.create(external_file_storage_id: self.id)
    GoogleDoc.create(external_file_storage_id: self.id)
    Ftp.create(external_file_storage_id: self.id)
    Box.create(external_file_storage_id: self.id)
    true
  end
end
