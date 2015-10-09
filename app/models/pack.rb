# -*- encoding : UTF-8 -*-
class Pack
  include Mongoid::Document
  include Mongoid::Timestamps
  include Elasticsearch::Model

  CODE_PATTERN = '[a-zA-Z0-9]+[%#]*[a-zA-Z0-9]*'
  JOURNAL_PATTERN = '[a-zA-Z0-9]+'
  PERIOD_PATTERN = '\d{4}([01T]\d)*'
  POSITION_PATTERN = '(all|\d{3})'
  EXTENSION_PATTERN = '\.(pdf|PDF)'
  FILENAME_PATTERN = /\A#{CODE_PATTERN}_#{JOURNAL_PATTERN}_#{PERIOD_PATTERN}_#{POSITION_PATTERN}#{EXTENSION_PATTERN}\z/

  belongs_to :owner, class_name: "User", inverse_of: :packs
  belongs_to :organization

  has_many :documents,                                                       dependent: :destroy
  has_many :pieces,           class_name: 'Pack::Piece',  inverse_of: :pack, dependent: :destroy, autosave: true
  has_many :reports,          class_name: 'Pack::Report', inverse_of: :pack
  has_many :period_documents
  has_many :remote_files,                                                    dependent: :destroy
  has_many :dividers,         class_name: 'PackDivider',  inverse_of: :pack, dependent: :destroy
  has_many :operations

  field :name,                 type: String
  field :original_document_id, type: String
  field :content_url,          type: String
  field :content_historic,     type: Array,   default: []
  field :tags,                 type: Array,   default: []
  field :pages_count,          type: Integer, default: 0
  field :scanned_pages_count,  type: Integer, default: 0
  field :is_update_notified,   type: Boolean, default: true
  field :is_fully_processed,   type: Boolean, default: true

  # for cache purpose
  field :remote_files_updated_at, type: Time

  index({ pages_count: 1 })
  index({ scanned_pages_count: 1 })
  index({ is_update_notified: 1 })

  validates_presence_of :name
  validates_uniqueness_of :name

  scope :scan_delivered,      -> { where(:scanned_pages_count.gt => 0) }
  scope :not_notified_update, -> { where(is_update_notified: false) }

  after_create { |pack| IndexerService.perform_async(Pack.to_s, pack.id.to_s, 'index') }
  after_update do |pack|
    keys = pack.__elasticsearch__.instance_variable_get(:@__changed_attributes).keys
    if keys.include?('updated_at') || keys.include?('tags')
      IndexerService.perform_async(Pack.to_s, pack.id.to_s, 'index')
    end
  end
  after_destroy { |pack| IndexerService.perform_async(Pack.to_s, pack.id.to_s, 'delete') }

  index_name "idocus_#{Rails.env}_packs"

  mapping dynamic: 'false' do
    indexes :id
    indexes :owner_id
    indexes :created_at, type: 'date'
    indexes :updated_at, type: 'date'
    indexes :name
    indexes :tags
    indexes :content_text
  end

  def as_indexed_json(options={})
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

  class << self
    def search(text, options={})
      page = options[:page].present? ? options[:page].to_i : 1
      per_page = options[:per_page].present? ? options[:per_page].to_i : self.default_per_page

      query = {}
      filter = {}
      filter[:id]    = options[:id]                      if options[:id].present?
      filter[:ids]   = { values: options[:ids] }         if options[:ids].present?
      filter[:term]  = { owner_id: options[:owner_id] }  if options[:owner_id].present?
      filter[:terms] = { owner_id: options[:owner_ids] } if options[:owner_ids].present?
      if filter.present? && text.present?
        query[:multi_match] = { query: text, fields: [:name, :tags, :content_text] }
      end

      sort = ['_score']
      sort = [{ updated_at: :desc }] if options[:sort] == true

      query_or_payload = nil
      if filter.present?
        query_or_payload = { sort: sort, filter: filter }
        query_or_payload.merge!({ query: query }) if query.present?
      elsif text.present?
        query_or_payload = text
      else
        raise 'query_or_payload must not be nil'
      end

      search = Elasticsearch::Model::Searching::SearchRequest.new(self, query_or_payload)
      response = Elasticsearch::Model::Response::Response.new(self, search)
      response.page(page).limit(per_page)
    end

    def client
      __elasticsearch__.client
    end
  end

  def content_text
    self.pages.map(&:content_text).join(' ')
  end

  def set_tags
    self.tags = original_document.tags
  end

  def set_pages_count
    self.scanned_pages_count = pages.scanned.size
    self.pages_count = pages.size
  end

  def set_original_document_id
    self.original_document_id = original_document.id.to_s
  end

  def set_content_url
    self.content_url = original_document.content.url
  end

  def set_historic
    self.content_historic = historic
  end

  def pages
    self.documents.not_mixed
  end

  def original_document
    documents.mixed.first
  end

  def sheets_info
    self.dividers.sheets
  end

  def pieces_info
    self.dividers.pieces
  end

  def cover_info
    pieces_info.covers.first
  end

  def has_cover?
    cover_info.present?
  end

  def cover_name
    cover_info.name.gsub('_',' ') rescue ''
  end

  def historic
    _documents = self.pages.asc(:created_at).entries
    current_date = _documents.first.created_at
    @events = [{:date => current_date, :uploaded => 0, :scanned => 0, :dematbox_scanned => 0, :fiduceo => 0}]
    current_offset = 0
    _documents.each do |document|
      if document.created_at > current_date.end_of_day
        current_date = document.created_at
        current_offset += 1
        @events << {:date => current_date, :uploaded => 0, :scanned => 0, :dematbox_scanned => 0, :fiduceo => 0}
      end
      if document.uploaded?
        @events[current_offset][:uploaded] += 1
      elsif document.dematbox_scanned?
        @events[current_offset][:dematbox_scanned] += 1
      elsif document.fiduceo?
        @events[current_offset][:fiduceo] += 1
      else
        @events[current_offset][:scanned] += 1
      end
    end
    @events
  end

  def archive_name
    name.gsub(/\s/,'_') + '.zip'
  end

  def archive_file_path
    File.join([Rails.root, 'files', Rails.env, 'archives', archive_name])
  end

  class << self
    def find_by_name(name)
      where(name: name).first
    end

    def find_or_initialize(name, user)
      find_by_name(name) || Pack.new(name: name, owner_id: user.id, organization_id: user.organization.try(:id))
    end

    def info_path(pack_name, receiver=nil)
      name_info = pack_name.split("_")
      pack = Pack.find_by_name(name_info.join(' '))
      info = {}
      info[:code] = name_info[0]
      if info[:code].match /%/
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
      info[:delivery_date]       = Time.now.strftime("%Y%m%d")
      info
    end
  end
end
