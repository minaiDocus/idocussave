# -*- encoding : UTF-8 -*-
class ExternalFileStorage
  include Mongoid::Document
  include Mongoid::Timestamps
  
  SERVICES = ["Dropbox","Google Drive","FTP"]
  
  F_DROPBOX     = 2
  F_GOOGLE_DOCS = 4
  F_FTP         = 8
  
  referenced_in :user
  references_one :dropbox_basic, autosave: true
  references_one :google_doc,    autosave: true
  references_one :ftp,           autosave: true

  accepts_nested_attributes_for :dropbox_basic, :google_doc, :ftp

  field :path,         type: String,  default: 'iDocus/:code/:year:month/:account_book/'
  field :is_path_used, type: Boolean, default: false
  field :used,         type: Integer, default: 0
  field :authorized,   type: Integer, default: 10

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
  
  def is_authorized?(flag)
    authorized & flag > 0
  end
  
  def services_authorized
    services  = []
    services << "Dropbox" if authorized & F_DROPBOX > 0
    services << "Google Drive" if authorized & F_GOOGLE_DOCS > 0
    services << "FTP" if authorized & F_FTP > 0
    services.join(", ")
  end
  
  def services_authorized_count
    nb = 0
    nb += 1 if authorized & F_DROPBOX > 0
    nb += 1 if authorized & F_GOOGLE_DOCS > 0
    nb += 1 if authorized & F_FTP > 0
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
    services  = []
    services << "Dropbox" if used & F_DROPBOX > 0
    services << "Google Drive" if used & F_GOOGLE_DOCS > 0
    services << "FTP" if used & F_FTP > 0
    services.join(", ")
  end
  
  def services_used_count
    nb = 0
    nb += 1 if used & F_DROPBOX > 0
    nb += 1 if used & F_GOOGLE_DOCS > 0
    nb += 1 if used & F_FTP > 0
    nb
  end
  
  def deliver(filespath, info_path={}, flags=used)
    is_ok = true
    filespath.each do |filepath|
      unless File.exist? filepath
        is_ok = false
      end
    end
    if is_ok
      trusted_flags =  authorized & used & flags
      delivery_path = ""
      
      if trusted_flags & F_DROPBOX > 0
        if dropbox_basic and dropbox_basic.is_configured?
          delivery_path = is_path_used ? path : dropbox_basic.path
          delivery_path = static_path(delivery_path,info_path)
          dropbox_basic.deliver filespath, delivery_path
        end
      end
      
      if trusted_flags & F_GOOGLE_DOCS > 0
        if google_doc and google_doc.is_configured?
          delivery_path = is_path_used ? path : google_doc.path
          delivery_path = static_path(delivery_path,info_path)
          google_doc.deliver(filespath, delivery_path)
        end
      end
      
      if trusted_flags & F_FTP > 0
        if ftp and ftp.is_configured?
          delivery_path = is_path_used ? path : ftp.path
          delivery_path = static_path(delivery_path,info_path)
          ftp.deliver(filespath, delivery_path)
        end
      end
    end
  end
  
  def static_path(path, info_path)
    path.gsub(":code",info_path[:code]).
    gsub(":company",info_path[:company]).
    gsub(":account_book",info_path[:account_book]).
    gsub(":year",info_path[:year]).
    gsub(":month",info_path[:month]).
    gsub(":delivery_date",info_path[:delivery_date])
  end
  
  protected

  def init_services
    DropboxBasic.create(external_file_storage_id: self.id)
    GoogleDoc.create(external_file_storage_id: self.id)
    Ftp.create(external_file_storage_id: self.id)
    true
  end
end
