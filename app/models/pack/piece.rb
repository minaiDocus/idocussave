# -*- encoding : UTF-8 -*-
class Pack::Piece
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Paperclip

  field :name,               type: String
  field :content_file_name
  field :content_file_type
  field :content_file_size,  type: Integer
  field :content_updated_at, type: Time
  field :is_an_upload,       type: Boolean, default: false
  field :position,           type: Integer
  field :token,              type: String

  belongs_to :pack,                                                 inverse_of: :pieces
  has_one    :expense,      class_name: "Pack::Report::Expense",    inverse_of: :piece
  has_many   :preseizures,  class_name: 'Pack::Report::Preseizure', inverse_of: :piece
  has_many   :remote_files, as: :remotable, dependent: :destroy

  has_mongoid_attached_file :content,
                            path: ":rails_root/files/#{Rails.env.test? ? 'test_' : ''}attachments/pieces/:id/:style/:filename",
                            url: "/account/documents/pieces/:id/download"

  scope :uploaded, where: { is_an_upload: true }
  scope :scanned,  where: { is_an_upload: false }

  scope :of_month, lambda { |time| where(created_at: { '$gt' => time.beginning_of_month, '$lt' => time.end_of_month }) }

  before_create :send_to_compta

  def self.by_position
    asc(:position)
  end

  def get_token
    if token.present?
      token
    else
      update_attribute(:token, rand(36**50).to_s(36))
      token
    end
  end

  def get_access_url
    content.url + "&token=" + get_token
  end

  def send_to_compta
    account_book = name.split(' ')[1]
    account_book_type = self.pack.owner.account_book_types.where(name: account_book).first rescue nil
    if account_book_type && account_book_type.compta_processable?
      compta_type = account_book_type.compta_type
      if self.is_an_upload
        path = File.join([Compta::ROOT_DIR,'input',Time.now.strftime('%Y%m%d'),'uploads',compta_type])
      else
        path = File.join([Compta::ROOT_DIR,'input',Time.now.strftime('%Y%m%d'),compta_type])
      end
      filename = ''
      filename = self.name.gsub(' ','_') + '_' + account_book_type.account_number + '_' + account_book_type.charge_account + '.pdf'
      FileUtils.mkdir_p(path)
      content_path = (self.content.queued_for_write[:original].presence || self.content).path
      FileUtils.cp(content_path, File.join([path,filename]))
    end
  end

  def get_tiff_file
    file_path = self.content.path
    temp_path = "/tmp/#{self.content_file_name.sub(/\.pdf$/,'.tiff')}"
    PdfDocument::Utils.generate_tiff_file(file_path, temp_path)
    temp_path
  end

  def get_remote_file(user,service_name,type='pdf')
    remote_file = remote_files.of(user,service_name).with_type(type).first
    remote_file ||= RemoteFile.new
    remote_file.user ||= user
    if type == 'pdf'
      remote_file.remotable ||= self
    elsif type == 'tiff'
      remote_file.temp_path = get_tiff_file
    end
    remote_file.pack ||= self.pack
    remote_file.service_name ||= service_name
    remote_file.save
    remote_file
  end

  def get_remote_files(user,service_name)
    current_remote_files = []
    if service_name == 'Dropbox Extended'
      if user.file_type_to_deliver.in? [ExternalFileStorage::ALL_TYPES, ExternalFileStorage::PDF, nil]
        current_remote_files << get_remote_file(user,service_name,'pdf')
      end
      if user.file_type_to_deliver.in? [ExternalFileStorage::ALL_TYPES, ExternalFileStorage::TIFF]
        current_remote_files << get_remote_file(user,service_name,'tiff')
      end
    else
      if user.external_file_storage.get_service_by_name(service_name).try(:file_type_to_deliver).in? [ExternalFileStorage::ALL_TYPES, ExternalFileStorage::PDF, nil]
        current_remote_files << get_remote_file(user,service_name,'pdf')
      end
      if user.external_file_storage.get_service_by_name(service_name).try(:file_type_to_deliver).in? [ExternalFileStorage::ALL_TYPES, ExternalFileStorage::TIFF]
        current_remote_files << get_remote_file(user,service_name,'tiff')
      end
    end
    current_remote_files
  end

  def init_remote_files(user, service_name)
    remote_files = get_remot_files(user, service_name)
    remote_files.each { |remote_file| remote_file.waiting! }
    remote_files
  end
end
