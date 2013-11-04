# -*- encoding : UTF-8 -*-
class Document
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Paperclip
  include Tire::Model::Search
  include Tire::Model::Callbacks

  field :content_file_name
  field :content_content_type
  field :content_file_size,    type: Integer
  field :content_updated_at,   type: Time
  field :content_text,         type: String,  default: ""
  field :is_a_cover,           type: Boolean, default: false
  field :origin
  field :tags,                 type: Array,   default: []
  field :position,             type: Integer
  field :dirty,                type: Boolean, default: true
  field :token

  validates_inclusion_of :origin, within: %w(mixed scan upload dematbox_scan)

  index :origin
  index :is_a_cover
  index :dirty

  has_many :remote_files,  as: :remotable, dependent: :destroy
  belongs_to :pack

  has_mongoid_attached_file :content,
                            styles: {
                                thumb: ["46x67>", :png],
                                medium: ["92x133", :png]
                            },
                            path: ":rails_root/files/:rails_env/:class/:attachment/:id/:style/:filename",
                            url: "/account/documents/:id/download/:style"

  before_content_post_process do |image|
    if image.dirty # halts processing
      false
    else
      true
    end
  end

  before_create :init_tags
  after_create :generate_thumbs!, :extract_content!, unless: Proc.new { |d| d.mixed? || Rails.env.test? }
  after_save :update_pack!

  scope :mixed,            where:  { origin: 'mixed' }
  scope :not_mixed,        not_in: { origin: ['mixed'] }

  scope :extracted,        not_in: { content_text: [""] }
  scope :not_extracted,    where:  { content_text: "" }
  scope :cannot_extract,   where:  { content_text: "-[none]" }

  scope :clean,            where:  { dirty: false }
  scope :not_clean,        where:  { dirty: true }

  scope :scanned,          where:  { origin: 'scan' }
  scope :uploaded,         where:  { origin: 'upload' }
  scope :dematbox_scanned, where:  { origin: 'dematbox_scan' }

  scope :covers,           where:  { is_a_cover: true }
  scope :not_covers,       any_in: { is_a_cover: [false, nil] }

  scope :of_month, lambda { |time| where(created_at: { '$gt' => time.beginning_of_month, '$lt' => time.end_of_month }) }

  mapping do
    indexes :id, as: 'stringified_id'
    indexes :pack_id
    indexes :created_at, type: 'date'
    indexes :tags
    indexes :content_file_name
    indexes :content_content_type
    indexes :content_text
    indexes :origin
    indexes :is_a_cover, type: 'boolean'
    indexes :position, type: 'integer'
  end

  def self.search(query, params = {})
    tire.search(page: params[:page], per_page: params[:per_page], load: true) do
      filter :term,  id:         params[:id]            if params[:id].present?
      filter :term,  pack_id:    params[:pack_id]       if params[:pack_id].present?
      filter :terms, origin:     Array(params[:origin]) if params[:origin].present?
      filter :term,  is_a_cover: params[:is_a_cover]    if params[:is_a_cover].present?
      sort { by :position, 'asc' }
      query { string(query) } if query.present?
    end
  end

  def stringified_id
    self.id.to_s
  end

  def update_pack!
    if (self.content_text_changed? || (self.mixed? && self.tags_changed?)) && pack.persisted?
      Pack.observers.disable :all do
        pack.timeless.save
      end
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

  class << self
    def by_position
      asc(:position)
    end
  end

  def generate_thumbs!
    self.dirty = false # set to false before reprocess to pass `before_content_post_process`
    self.content.reprocess!
    save
  end
  handle_asynchronously :generate_thumbs!, queue: 'documents thumbs', priority: 1, :run_at => Proc.new { 5.minutes.from_now }

  def extract_content!
    if self.content.queued_for_write[:original]
      path = self.content.queued_for_write[:original].path
    else
      path = self.content.path
    end
    words = []
    `pdftotext -raw -nopgbrk -q #{path}`
    dirname = File.dirname(path)
    filename = File.basename(path, '.pdf') + '.txt'
    filepath = File.join(dirname, filename)
    if File.exist?(filepath)
      text = File.open(filepath, 'r').readlines.map(&:strip).join(' ')
      text.split().each do |dirty_word|
        word = dirty_word.scan(/[[:alpha:]|@|_|-]+/).join().downcase
        words << word if word.present?
      end
      self.content_text = words.join(' ')
    end
    self.content_text = '-[none]' unless self.content_text.present?

    if uploaded? && self.content_text == '-[none]'
      tess = Tesseract::Process.new(path, lang: :fra, convert_options: { input: ["-density 200 -colorspace Gray -depth 8 -alpha off"] } )
      words = tess.to_s.split(/\n/).join(' ').split(' ').uniq.select { |e| e.size > 1 }
      self.content_text = words.join(' ')
      self.content_text = ' ' unless self.content_text.presence
    end
    save if self.content_text_changed?
  end
  handle_asynchronously :extract_content!, queue: 'documents content', priority: 10, :run_at => Proc.new { 5.minutes.from_now }
end
