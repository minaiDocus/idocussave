# -*- encoding : UTF-8 -*-
class Pack < ActiveRecord::Base
  serialize :delivered_user_ids, Hash
  serialize :processed_user_ids, Hash


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
  has_many :remote_files, dependent: :destroy


  validates_presence_of :name
  validates_uniqueness_of :name


  scope :scan_delivered,      -> { where("scanned_pages_count > ? ", 0) }
  scope :not_notified_update, -> { where(is_update_notified: false) }


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


  def self.search(text, options = {})
    page = options[:page].present? ? options[:page].to_i : 1
    per_page = options[:per_page].present? ? options[:per_page].to_i : default_per_page

    query = self
    query = query.where(id: options[:id]) if options[:id].present?
    query = query.where(id: options[:ids]) if options[:ids].present?
    query = query.where(owner_id: options[:owner_id])  if options[:owner_id].present?
    query = query.where(owner_id: options[:owner_ids]) if options[:owner_ids].present?
    query = query.joins(:documents).where('packs.tags LIKE ?  OR packs.name LIKE ? OR documents.content_text LIKE ?' , "%#{text}%",  "%#{text}%", "%#{text}%") if text.present?

    query = query.order(updated_at: :desc)

    query.distinct('packs.id').page(page).limit(per_page)
  end


  def content_text
    pages.map(&:content_text).join(' ')
  end


  def set_tags
    self.tags = original_document.tags
  end


  def set_pages_count
    self.scanned_pages_count = pages.scanned.size

    self.pages_count = pages.size
  end


  def set_original_document_id
    self.original_document_id = original_document.id
  end


  def set_content_url
    self.content_url = original_document.content.url
  end


  def set_historic
    self.content_historic = historic
  end


  def pages
    documents.not_mixed
  end


  def original_document
    documents.mixed.first
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

    @events
  end


  def archive_name
    name.gsub(/\s/, '_') + '.zip'
  end


  def archive_file_path
    File.join([Rails.root, 'files', Rails.env, 'archives', archive_name])
  end


  def self.find_by_name(name)
    where(name: name).first
  end


  def self.find_or_initialize(name, user)
    find_by_name(name) || Pack.new(name: name, owner_id: user.id, organization_id: user.organization.try(:id), created_at: Time.now, updated_at: Time.now)
  end


  def self.info_path(pack_name, receiver = nil)
    name_info = pack_name.split('_')
    pack = Pack.find_by_name(name_info.join(' '))

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
end
