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

  def cloud_content_object
    CustomActiveStorageObject.new(self, :cloud_content)
  end

  def user
    owner
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


  def archive_name
    name.gsub(/\s/, '_') + '.zip'
  end


  def archive_file_path
    dir = "#{Rails.root}/tmp/archives/#{self.id}"
    zip_path = File.join(dir, archive_name)

    unless File.exist?(zip_path)
      FileUtils.makedirs(dir)
      FileUtils.chmod(0755, dir)

      pieces.each do |piece|
        piece_file_path = piece.cloud_content_object.path
        FileUtils.copy piece_file_path, File.join(dir, File.basename(piece_file_path)) if File.exist?(piece_file_path)
      end

      POSIX::Spawn::system "zip #{zip_path} #{dir}/*"
      FileUtils.delay_for(5.minutes, queue: :low).remove_dir(dir, true)
    end

    zip_path
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

  def append(file_path, overwrite_original = false, tmp_dir = nil)
    return _append(file_path, tmp_dir, overwrite_original) if tmp_dir

    Dir.mktmpdir do |dir|
      _append(file_path, dir, overwrite_original)
    end
  end


  def prepend(file_path, dir = nil)
    return false if dir.nil?

    original_file = original_document.cloud_content_object
    new_file_name = self.name.tr(' ', '_') + '.pdf'

    if File.exist? original_file.path.to_s
      merged_file_path = File.join(dir, new_file_name)
      Pdftk.new.merge([file_path, original_file.path], merged_file_path)
    else
      merged_file_path = File.join(dir, new_file_name)
      FileUtils.copy file_path, merged_file_path
    end

    if DocumentTools.modifiable?(merged_file_path)
      original_document.cloud_content_object.attach(File.open(merged_file_path), new_file_name) if original_document.save
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
    return false if self.locked_at.present?

    self.update(locked_at: Time.now)
    pieces  = self.pieces.by_position
    success = false
    sleep_counter = 5

    if pieces.present?
      Dir.mktmpdir do |dir|
        pieces.each do |piece|
          success = append(piece.cloud_content_object.path, true, dir)

          break unless success
          #add a sleeping time to prevent disk access overload
          sleep_counter -= 1
          if sleep_counter <= 0
            sleep(10)
            sleep_counter = 5
          end
        end
      end

      temp_file_path = self.original_document.cloud_content_object.path.to_s.gsub('.pdf', '_2.pdf')

      if success
        original_document.cloud_content_object.attach(File.open(temp_file_path), self.name.tr(' ', '_') + '.pdf') if original_document.save && File.exist?(temp_file_path) && DocumentTools.modifiable?(temp_file_path)

        set_pages_count
        save
      end

      FileUtils.rm temp_file_path if File.exist? temp_file_path
    else
      self.original_document.cloud_content.purge
    end

    self.update(locked_at: nil)
  end

  private

  def _append(file_path, dir, overwrite_original = false)
    original_file = original_document.cloud_content_object
    target_file_name = overwrite_original ? self.name.tr(' ', '_') + '_2.pdf' : self.name.tr(' ', '_') + '.pdf'
    target_file_path = overwrite_original ? original_file.path.to_s.gsub('.pdf', '_2.pdf') : original_file.path

    merged_file_path = File.join(dir, target_file_name)
    FileUtils.rm merged_file_path if File.exist? merged_file_path

    if File.exist? target_file_path.to_s
      Pdftk.new.merge([target_file_path, file_path], merged_file_path)
    else
      FileUtils.copy file_path, merged_file_path
    end

    if !overwrite_original && DocumentTools.modifiable?(merged_file_path)
      original_document.cloud_content_object.attach(File.open(merged_file_path), target_file_name) if original_document.save
      return true
    elsif overwrite_original
      begin
        FileUtils.copy merged_file_path, target_file_path
        return true
      rescue
        FileUtils.rm target_file_path if File.exist? target_file_path
        return false
      end
    else
      return false
    end
  end
end