# -*- encoding : UTF-8 -*-
class Pack < ApplicationRecord
  ATTACHMENTS_URLS={'cloud_content' => '/account/documents/pack/:id/download'}

  serialize :delivered_user_ids, Hash
  serialize :processed_user_ids, Hash
  serialize :content_historic, Array
  serialize :tags, Array

  CODE_PATTERN      = '[a-zA-Z0-9]+[%#]*[a-zA-Z0-9]*'.freeze
  PERIOD_PATTERN    = '\d{4}([01T]\d)*'.freeze
  JOURNAL_PATTERN   = '[a-zA-Z0-9]+'.freeze
  POSITION_PATTERN  = '(all|\d{3})'.freeze
  EXTENSION_PATTERN = '\.(pdf|PDF)'.freeze

  FILENAME_PATTERN  = /\A#{CODE_PATTERN}_#{JOURNAL_PATTERN}_#{PERIOD_PATTERN}_#{POSITION_PATTERN}#{EXTENSION_PATTERN}\z/


  belongs_to :owner, class_name: 'User', inverse_of: :packs
  belongs_to :organization


  has_many :pieces,    class_name: 'Pack::Piece',  inverse_of: :pack, dependent: :destroy, autosave: true
  has_many :reports,   class_name: 'Pack::Report', inverse_of: :pack
  has_many :dividers,  class_name: 'PackDivider', inverse_of: :pack, dependent: :destroy
  has_many :documents, dependent: :destroy
  has_many :operations
  has_many :period_documents
  has_many :self_remote_files, class_name: 'RemoteFile', as: :remotable, dependent: :destroy
  has_many :remote_files, dependent: :destroy
  has_many :preseizures, through: :reports

  has_one_attached :cloud_content
  has_one_attached :cloud_archive

  has_attached_file :content, path: ':rails_root/files/:rails_env/:class/:attachment/:mongo_id_or_id/:style/:filename',
                              url: '/account/documents/pack/:id/download'
  do_not_validate_attachment_file_type :content

  Paperclip.interpolates :mongo_id_or_id do |attachment, style|
    attachment.instance.mongo_id || attachment.instance.id
  end

  validates_presence_of :name
  validates_uniqueness_of :name

  scope :scan_delivered,      -> { where("scanned_pages_count > ? ", 0) }
  scope :not_notified_update, -> { where(is_update_notified: false) }

  before_destroy do |pack|
    pack.cloud_content.purge
    pack.cloud_archive.purge
  end

  def as_indexed_json(_options = {})
    {
      id:           id.to_s,
      owner_id:     owner.id.to_s,
      created_at:   created_at,
      updated_at:   updated_at,
      name:         name,
      tags:         tags,
      content_text: content_text
    }
  end

  def self.recreate_original_document(pack_id)
    pack = Pack.find pack_id
    pack.recreate_original_document
  end

  def self.search(text, options = {})
    page = options[:page].present? ? options[:page].to_i : 1
    per_page = options[:per_page].present? ? options[:per_page].to_i : default_per_page

    query = self
    query = query.where(id: options[:ids]) if options[:ids].present?
    
    # WARN : do not change "unless..nil?" to "if..present?, an empty owner_ids must be passed to the query
    query = query.where(owner_id: options[:owner_ids]) unless options[:owner_ids].nil?
    query = query.joins(:pieces).where(pack_pieces: { id: options[:piece_ids] }) unless options[:piece_ids].nil?

    query = query.joins(:pieces).where('packs.name LIKE ? OR packs.tags LIKE ? OR pack_pieces.name LIKE ? OR pack_pieces.tags LIKE ? OR pack_pieces.content_text LIKE ?' , "%#{text}%", "%#{text}%", "%#{text}%",  "%#{text}%", "%#{text}%") if text.present?

    query = query.where('packs.name LIKE ?', "%#{options[:name]}%") if options[:name].present?
    query = query.joins(:pieces).where("packs.tags LIKE ? OR pack_pieces.tags LIKE ?", "%#{options[:tags]}%", "%#{options[:tags]}%") if options[:tags].present?

    query = query.joins(:pieces).where("DATE_FORMAT(pack_pieces.created_at, '%Y-%m-%d') #{options[:piece_created_at_operation].tr('012', ' ><')}= ?", options[:piece_created_at]) if options[:piece_created_at]
    query = query.joins(:pieces).where("pack_pieces.position #{options[:piece_position_operation].tr('012', ' ><')}= ?", options[:piece_position]) if options[:piece_position].present?

    query = query.joins(:pieces).where(pack_pieces: { pre_assignment_state: options[:pre_assignment_state].try(:split, ',') }) if options[:pre_assignment_state].present?

    query = query.order(updated_at: :desc) if options[:sort] == true

    query.distinct.page(page).per(per_page)
  end

  def self.count_pages_of(documents)
    if documents.first.is_a? Document
      documents.size
    else
      documents.inject(0){ |memo, piece| memo + piece.get_pages_number }
    end
  end

  def self.store_archive_of(pack_id)
    Pack.find(pack_id).save_archive_to_storage
  end

  def cloud_content_object
    CustomActiveStorageObject.new(self, :cloud_content)
  end

  def cloud_archive_object
    CustomActiveStorageObject.new(self, :cloud_archive)
  end

  #this method is required to avoid custom_active_storage bug when seeking for paperclip equivalent method
  def archive
    object = FakeObject.new
  end

  def user
    owner
  end

  def pdf_name
    self.name.tr(' ', '_') + '.pdf'
  end

  def journal
    owner.account_book_types.where(name: name.split[1]).first if owner
  end

  def content_text
    pages.map(&:content_text).join(' ')
  end

  def has_documents?
    documents.count > 0
  end

  def set_tags
    self.tags = original_document.tags.presence || name.downcase.sub(' all', '').split
  end

  def set_pages_count
    if pages(false).first.is_a? Document
      self.scanned_pages_count = pages.scanned.size

      self.pages_count = pages.size
    else
      
      self.scanned_pages_count = pages(false).scanned.inject(0){ |memo, piece| memo + piece.get_pages_number }
    
      self.pages_count = pages(false).inject(0){ |memo, piece| memo + piece.get_pages_number }
    end
  end


  def set_original_document_id
    self.original_document_id = original_document.id
  end


  def set_content_url
    self.content_url = original_document.cloud_content_object.url
  end


  def set_historic
    self.content_historic = historic
  end


  def pages(with_deleted = true)
    @pages ||= documents.not_mixed.presence || ( with_deleted ? pieces.unscoped.where(pack_id: self.id) : pieces  )
  end

  def original_document
    @original ||= documents.mixed.first || self
  end


  def sheets_info
    dividers.sheets
  end


  def pieces_info
    dividers.pieces
  end


  def cover_info
    pieces_info.covers.first
  end


  def has_cover?
    cover_info.present?
  end


  def cover_name
    cover_info.name.tr('_', ' ')
  rescue
    ''
  end


  def historic
    _documents = pages.order(created_at: :asc)

    @events = [{ date: self.created_at, uploaded: 0, scanned: 0, dematbox_scanned: 0, retrieved: 0 }]

    if _documents.any?
      current_date = _documents.first.created_at

      @events = [{ date: current_date, uploaded: 0, scanned: 0, dematbox_scanned: 0, retrieved: 0 }]

      current_offset = 0

      _documents.each do |document|
        if document.created_at > current_date.end_of_day
          current_date = document.created_at
          current_offset += 1
          @events << { date: current_date, uploaded: 0, scanned: 0, dematbox_scanned: 0, retrieved: 0 }
        end

        if document.uploaded?
          @events[current_offset][:uploaded] += 1
        elsif document.dematbox_scanned?
          @events[current_offset][:dematbox_scanned] += 1
        elsif document.retrieved?
          @events[current_offset][:retrieved] += 1
        else
          @events[current_offset][:scanned] += 1
        end
      end
    end

    @events
  end

  def is_locked?
    return false if !self.locked_at.present?

    self.locked_at > 1.hours.ago
  end


  def archive_name
    name.gsub(/\s/, '_') + '_' + pieces.size.to_s + '.zip'
  end


  def archive_file_path
    dir      = "#{Rails.root}/tmp/archives/#{self.id}"
    zip_path = File.join(dir, archive_name)

    unless File.exist?(zip_path)
      FileUtils.makedirs(dir)
      FileUtils.chmod(0755, dir)

      files_paths = []
      pieces.each do |piece|
        piece_file_path = piece.cloud_content_object.path.to_s
        files_paths << piece_file_path if File.exist?(piece_file_path)
      end

      DocumentTools.archive(zip_path, files_paths) if files_paths.present?
      FileUtils.delay_for(5.minutes, queue: :low).remove_entry(dir, true)
    end

    zip_path
  end

  def save_archive_to_storage
    archive_file = archive_file_path
    cloud_archive_object.attach(File.open(archive_file), archive_name) if File.exist?(archive_file)
  end

  def self.find_by_name(name)
    where(name: name).first
  end


  def self.find_or_initialize(name, user)
    self.find_or_initialize_by(name: name) do |pack|
      pack.name = name
      pack.owner_id = user.id
      pack.organization_id = user.organization.try(:id)

      pack
    end
  end


  def self.info_path(pack, receiver = nil)
    name_info = pack.name.split(' ')

    info = {}
    info[:code] = name_info[0]

    if info[:code] =~ /%/
      info[:organization_code] = info[:code].split('%')[0]
      info[:customer_code]     = info[:code].split('%')[1]
    else
      info[:organization_code] = ''
      info[:customer_code]     = info[:code]
    end

    if receiver.class.name == User.name
      info[:company] = receiver.try(:company)
    else
      info[:group]   = receiver.try(:name)
    end

    info[:company_of_customer] = pack.owner.company
    info[:account_book]        = name_info[1]
    info[:year]                = name_info[2][0..3]
    info[:month]               = name_info[2][4..5]
    info[:delivery_date]       = Time.now.strftime('%Y%m%d')

    info
  end

  def append(file_path, tmp_dir = nil, append_to = nil)
    return merge_document('append', file_path, tmp_dir, append_to) if tmp_dir

    CustomUtils.mktmpdir('pack_1') do |dir|
      merge_document('append', file_path, dir, append_to)
    end
  end


  def prepend(file_path, tmp_dir = nil, prepend_to = nil)
    return merge_document('prepend', file_path, tmp_dir, prepend_to) if tmp_dir

    CustomUtils.mktmpdir('pack_2') do |dir|
      merge_document('prepend', file_path, dir, prepend_to)
    end
  end

  def get_delivery_message_of(software='ibiza')
    message = ''

    self.reports.each do |report|
      message = report.get_delivery_message_of(software)
      return message if message.present?
    end

    message
  end

  def recreate_original_document
    return false if self.is_locked?

    pieces  = self.pieces.by_position
    sleep_counter = 5

    if pieces.present?
      CustomUtils.mktmpdir('pack_3') do |dir|
        temp_final_file = File.join(dir, self.pdf_name.gsub('.pdf', '_temp.pdf'))
        FileUtils.rm temp_final_file, force: true

        pieces.each do |piece|
          self.update(locked_at: Time.now)

          append(piece.cloud_content_object.path, dir, temp_final_file)

          #add a sleeping time to prevent disk access overload
          sleep_counter -= 1
          if sleep_counter <= 0
            sleep(5)
            sleep_counter = 5
          end
        end

        if original_document.save && File.exist?(temp_final_file) && DocumentTools.modifiable?(temp_final_file)
          original_document.cloud_content_object.attach(File.open(temp_final_file), self.pdf_name)

          set_pages_count
          save
        end
      end
    else
      self.original_document.cloud_content.purge
    end

    self.update(locked_at: nil)
  end

  private

  def merge_document(merge_type, file_path, dir, append_to = nil)
    target_file     = append_to.presence || original_document.cloud_content_object.path
    temp_file_merge = File.join(dir, "temp_file_merge_#{Time.now.strftime('%Y%m%d%H%M%S')}.pdf")
    is_merged       = true
    error_reason    = 'File not merged'
    retry_again     = 0

    begin
      if File.exist?(target_file.to_s)
        data_merge = (merge_type == 'append')? [target_file, file_path] : [file_path, target_file]
        is_merged = Pdftk.new.merge(data_merge, temp_file_merge, merge_type)
      else
        begin
          FileUtils.copy file_path, temp_file_merge
        rescue => e
          error_reason = "Copy failed => #{e}"
          is_merged = false
        end
      end

      raise if !is_merged && retry_again < 3
    rescue
      retry_again += 1
      sleep(20)
      retry
    end

    if is_merged
      if append_to.present?
        FileUtils.copy temp_file_merge, append_to
      else
        original_document.cloud_content_object.attach(File.open(temp_file_merge), self.pdf_name) if original_document.save
      end

      FileUtils.rm temp_file_merge, force: true
      return true
    else
      log_document = {
        subject: "[Pack] pdftk fail merged",
        name: "Pack",
        error_group: "[pack] Pdftk fail merged",
        erreur_type: "Pdftk fail merged",
        date_erreur: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
        more_information: {
          merge_type: merge_type,
          target_file_path: target_file,
          file_path: file_path,
          error_reason: error_reason,
          modifiable_target_pdf?: DocumentTools.modifiable?(target_file).to_s
        }
      }

      ErrorScriptMailer.error_notification(log_document).deliver

      return false
    end
  end
end