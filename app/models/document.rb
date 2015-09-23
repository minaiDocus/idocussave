# -*- encoding : UTF-8 -*-
class Document
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Paperclip
  include Elasticsearch::Model

  field :content_text, type: String,  default: ""
  field :is_a_cover,   type: Boolean, default: false
  field :origin
  field :tags,         type: Array,   default: []
  field :position,     type: Integer
  field :dirty,        type: Boolean, default: true
  field :token

  validates_inclusion_of :origin, within: %w(mixed scan upload dematbox_scan fiduceo)

  index({ origin: 1 })
  index({ is_a_cover: 1 })
  index({ dirty: 1 })

  has_many :remote_files,  as: :remotable, dependent: :destroy
  belongs_to :pack

  has_mongoid_attached_file :content,
                            styles: {
                                thumb: ["46x67>", :png],
                                medium: ["92x133", :png]
                            },
                            path: ":rails_root/files/:rails_env/:class/:attachment/:id/:style/:filename",
                            url: "/account/documents/:id/download/:style"
  do_not_validate_attachment_file_type :content

  before_content_post_process do |image|
    if image.dirty # halts processing
      false
    else
      true
    end
  end

  before_create :init_tags

  after_create do |document|
    IndexerService.perform_async(Document.to_s, document.id.to_s, 'index')
    unless document.mixed? || Rails.env.test?
      Document.delay(priority: 9, run_at: 5.minutes.from_now).
        generate_thumbs(document.id.to_s)
      Document.delay(priority: 10, run_at: 5.minutes.from_now).
        extract_content(document.id.to_s)
    end
  end

  after_update do |document|
    keys = document.__elasticsearch__.instance_variable_get(:@__changed_attributes).keys
    if keys.include?('content_text') || keys.include?('tags')
      IndexerService.perform_async(Document.to_s, document.id.to_s, 'index')
    end
  end

  after_destroy { |document| IndexerService.perform_async(Document.to_s, document.id.to_s, 'delete') }

  scope :mixed,            -> { where(origin: 'mixed') }
  scope :not_mixed,        -> { not_in(origin: ['mixed']) }

  scope :extracted,        -> { not_in(content_text: [""]) }
  scope :not_extracted,    -> { where(content_text: "") }
  scope :cannot_extract,   -> { where(content_text: "-[none]") }

  scope :clean,            -> { where(dirty: false) }
  scope :not_clean,        -> { where(dirty: true) }

  scope :scanned,          -> { where(origin: 'scan') }
  scope :uploaded,         -> { where(origin: 'upload') }
  scope :dematbox_scanned, -> { where(origin: 'dematbox_scan') }
  scope :fiduceo,          -> { where(origin: 'fiduceo') }

  scope :covers,           -> { where(is_a_cover: true) }
  scope :not_covers,       -> { any_in(is_a_cover: [false, nil]) }

  scope :of_period, lambda { |time, duration|
    case duration
    when 1
      start_at = time.beginning_of_month
      end_at   = time.end_of_month
    when 3
      start_at = time.beginning_of_quarter
      end_at   = time.end_of_quarter
    when 12
      start_at = time.beginning_of_year
      end_at   = time.end_of_year
    end
    where(created_at: { '$gte' => start_at, '$lte' => end_at })
  }

  index_name "idocus_#{Rails.env}_documents"

  mapping dynamic: 'false' do
    indexes :id
    indexes :pack_id
    indexes :created_at, type: 'date'
    indexes :tags
    indexes :content_text
    indexes :origin
    indexes :is_a_cover, type: 'boolean'
    indexes :position, type: 'integer'
  end

  def as_indexed_json(options={})
    {
      id:           id.to_s,
      pack_id:      pack_id.to_s,
      created_at:   created_at,
      tags:         tags,
      content_text: content_text,
      origin:       origin,
      is_a_cover:   is_a_cover,
      position:     position
    }
  end

  class << self
    def search(text, options={})
      page = options[:page] || 1
      per_page = options[:per_page] || self.default_per_page

      query = {}
      filter = {}
      filter[:id]    = options[:id]                    if options[:id].present?
      filter[:ids]   = { values: options[:ids] }       if options[:ids].present?
      filter[:term]  = { pack_id: options[:pack_id] }  if options[:pack_id].present?
      filter[:terms] = { pack_id: options[:pack_ids] } if options[:pack_ids].present?
      if filter.present? && text.present?
        query[:multi_match] = { query: text, fields: [:tags, :content_text] }
      end

      sort = ['_score']
      sort = [{ position: :asc }] if options[:sort] == true

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

    def generate_thumbs(id)
      document = Document.find id
      document.dirty = false # set to false before reprocess to pass `before_content_post_process`
      document.content.reprocess!
      document.save
    end

    def extract_content(id)
      document = Document.find id
      if document.content.queued_for_write[:original]
        path = document.content.queued_for_write[:original].path
      else
        path = document.content.path
      end
      POSIX::Spawn::system "pdftotext -raw -nopgbrk -q #{path}"
      dirname = File.dirname(path)
      filename = File.basename(path, '.pdf') + '.txt'
      filepath = File.join(dirname, filename)
      if File.exist?(filepath)
        text = File.open(filepath, 'r').readlines.map(&:strip).join(' ')
        document.content_text = text
      end
      document.content_text = ' ' unless document.content_text.present?
      document.save
    end
  end

  def get_token
    if token.present?
      token
    else
      update_attribute(:token, rand(36**50).to_s(36))
      token
    end
  end

  def get_access_url(style=:original)
    content.url(style) + "&token=" + get_token
  end

  def append(file_path)
    Dir.mktmpdir do |dir|
      merged_file_path = File.join(dir, content_file_name)
      Pdftk.new.merge([self.content.path, file_path], merged_file_path)
      self.content = open(merged_file_path)
      save
    end
  end

  def prepend(file_path)
    Dir.mktmpdir do |dir|
      merged_file_path = File.join(dir, content_file_name)
      Pdftk.new.merge([file_path, self.content.path], merged_file_path)
      self.content = open(merged_file_path)
      save
    end
  end

  def init_tags
    self.tags = pack.name.downcase.sub(' all', '').split
    if !self.mixed? && number
      self.tags << number
    end
  end

  def number
    self.content_file_name.split('_')[-1].to_i.to_s rescue nil
  end

  def mixed?
    origin == 'mixed'
  end

  def scanned?
    origin == 'scan'
  end

  def uploaded?
    origin == 'upload'
  end

  def dematbox_scanned?
    origin == 'dematbox_scan'
  end

  def fiduceo?
    origin == 'fiduceo'
  end

  class << self
    def by_position
      asc(:position)
    end
  end
end
