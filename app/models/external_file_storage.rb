# -*- encoding : UTF-8 -*-
class ExternalFileStorage < ApplicationRecord
  SERVICES = ['Dropbox', 'Dropbox Extended', 'Google Drive', 'FTP', 'SFTP', 'Box', 'Knowings', 'My Company Files'].freeze

  F_DROPBOX     = 2
  F_GOOGLE_DOCS = 4
  F_FTP         = 8
  F_BOX         = 16
  F_SFTP        = 32

  has_one :dropbox_basic, autosave: true, dependent: :destroy
  has_one :google_doc,    autosave: true, dependent: :destroy
  has_one :sftp,          autosave: true, dependent: :destroy
  has_one :ftp,           autosave: true, dependent: :destroy
  has_one :box,           autosave: true, dependent: :destroy


  belongs_to :user


  accepts_nested_attributes_for :dropbox_basic, :google_doc, :ftp, :box


  after_create :init_services


  def authorize(flags)
    update(authorized: authorized | flags)
  end


  def unauthorize(flags)
    update(authorized: authorized ^ (authorized & flags))
  end


  def is_dropbox_basic_authorized?
    authorized & F_DROPBOX > 0
  end


  def is_dropbox_basic_authorized
    is_dropbox_basic_authorized?
  end


  def is_dropbox_basic_authorized=(value)
    ok = value.to_i == 1

    self.authorized = ok ? authorized | F_DROPBOX : authorized ^ F_DROPBOX
  end


  def is_google_docs_authorized?
    authorized & F_GOOGLE_DOCS > 0
  end


  def is_google_docs_authorized
    is_google_docs_authorized?
  end


  def is_google_docs_authorized=(value)
    ok = value.to_i == 1

    self.authorized = ok ? authorized | F_GOOGLE_DOCS : authorized ^ F_GOOGLE_DOCS
  end


  def is_ftp_authorized?
    authorized & F_FTP > 0
  end


  def is_ftp_authorized
    is_ftp_authorized?
  end


  def is_ftp_authorized=(value)
    ok = value.to_i == 1

    self.authorized = ok ? authorized | F_FTP : authorized ^ F_FTP
  end

  def is_sftp_authorized?
    authorized & F_SFTP > 0
  end


  def is_sftp_authorized
    is_sftp_authorized?
  end


  def is_sftp_authorized=(value)
    ok = value.to_i == 1

    self.authorized = ok ? authorized | F_SFTP : authorized ^ F_SFTP
  end


  def is_box_authorized?
    authorized & F_BOX > 0
  end


  def is_box_authorized
    is_box_authorized?
  end


  def is_box_authorized=(value)
    ok = value.to_i == 1

    self.authorized = ok ? authorized | F_BOX : authorized ^ F_BOX
  end


  def is_authorized?(flag)
    authorized & flag > 0
  end


  def services_authorized
    services = []
    services << 'Dropbox'          if authorized & F_DROPBOX > 0
    services << 'Dropbox Extended' if user.is_dropbox_extended_authorized
    services << 'Google Drive'     if authorized & F_GOOGLE_DOCS > 0
    services << 'FTP'              if authorized & F_FTP > 0
    services << 'SFTP'             if authorized & F_SFTP > 0
    services << 'Box'              if authorized & F_BOX > 0
    services.join(', ')
  end


  def services_authorized_count
    nb = 0

    nb += 1 if authorized & F_DROPBOX > 0
    nb += 1 if user.is_dropbox_extended_authorized
    nb += 1 if authorized & F_GOOGLE_DOCS > 0
    nb += 1 if authorized & F_FTP > 0
    nb += 1 if authorized & F_SFTP > 0
    nb += 1 if authorized & F_BOX > 0

    nb
  end


  def use(flags)
    trusted_flags = authorized & flags

    if trusted_flags == flags && services_used_count < 2
      update(used: used | trusted_flags)
    else
      false
    end
  end


  def unuse(flags)
    update(used: used ^ (used & flags))
  end


  def is_used?(flag)
    used & flag > 0
  end


  def services_used
    active_services_name.join(', ')
  end


  def services_used_count
    nb = 0

    nb += 1 if used & F_DROPBOX > 0
    nb += 1 if used & F_GOOGLE_DOCS > 0
    nb += 1 if used & F_FTP > 0
    nb += 1 if used & F_SFTP > 0
    nb += 1 if used & F_BOX > 0

    nb
  end


  def active_services_name
    services = []
    services << 'Dropbox'          if (authorized & used & F_DROPBOX > 0) && dropbox_basic.is_configured?
    services << 'Dropbox Extended' if user.is_dropbox_extended_authorized
    services << 'Google Drive'     if (authorized & used & F_GOOGLE_DOCS > 0) && google_doc.is_configured?
    services << 'FTP'              if (authorized & used & F_FTP         > 0) && ftp.is_configured?
    services << 'SFTP'             if (authorized & used & F_SFTP         > 0) && sftp.is_configured?
    services << 'Box'              if (authorized & used & F_BOX         > 0) && box.is_configured?
    services
  end


  def dropbox_extended
    DropboxExtended if user.is_dropbox_extended_authorized
  end


  def self.static_path(path, info_path)
    path.gsub(':code',                info_path[:code])
        .gsub(':customer_code',       info_path[:customer_code])
        .gsub(':organization_code',   info_path[:organization_code] || '')
        .gsub(':company',             info_path[:company] || '')
        .gsub(':group',               info_path[:group] || '')
        .gsub(':company_of_customer', info_path[:company_of_customer])
        .gsub(':account_book',        info_path[:account_book])
        .gsub(':year',                info_path[:year])
        .gsub(':month',               info_path[:month])
        .gsub(':delivery_date',       info_path[:delivery_date])
        .split('/').select(&:present?).join('/')
  end


  def self.delivery_path(remote_file, path_pattern)
    info_path = Pack.info_path(remote_file.pack, remote_file.receiver)

    result = static_path(path_pattern.sub(/\/\z/, ''), info_path)
    result = '/' + result if remote_file.service_name.in?(['Dropbox', 'Dropbox Extended', 'FTP', 'SFTP'])
    result
  end


  def get_service_by_name(name)
    case name
    when 'Dropbox'
      dropbox_basic
    when 'Dropbox Extended'
      DropboxExtended
    when 'Google Drive'
      google_doc
    when 'FTP'
      ftp
    when 'SFTP'
      sftp
    when 'Box'
      box
    end
  end

  protected


  def init_services
    DropboxBasic.create(external_file_storage_id: id)
    GoogleDoc.create(external_file_storage_id: id)
    Ftp.create(external_file_storage_id: id)
    Sftp.create(external_file_storage_id: id)
    Box.create(external_file_storage_id: id)

    true
  end
end
