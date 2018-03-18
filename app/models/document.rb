# -*- encoding : UTF-8 -*-
class Document < ActiveRecord::Base
  serialize :tags


  validates :origin, inclusion: { within: %w(mixed scan upload dematbox_scan retriever) }


  has_many :remote_files, as: :remotable, dependent: :destroy

  belongs_to :pack

  has_attached_file :content,
                            styles: {
                              thumb: ['46x67>', :png],
                              medium: ['92x133', :png]
                            },
                            path: ':rails_root/:new_or_old_document_folder/:rails_env/:class/:attachment/:mongo_id_or_id/:style/:filename',
                            url: '/account/documents/:id/download/:style'
  do_not_validate_attachment_file_type :content

  Paperclip.interpolates :mongo_id_or_id do |attachment, style|
    attachment.instance.mongo_id || attachment.instance.id
  end

  Paperclip.interpolates :new_or_old_document_folder do |attachment, style|
    # Copy file from old directory if missing
    cid = attachment.instance.mongo_id || attachment.instance.id
    old_path = Rails.root.join('files_old', Rails.env, 'documents', 'contents', cid.to_s, style.to_s, attachment.instance.content_file_name)
    new_path = Rails.root.join('files', Rails.env, 'documents', 'contents', cid.to_s, style.to_s, attachment.instance.content_file_name)
    if File.exist?(old_path) && !File.exist?(new_path)
      dir = File.dirname new_path
      prev_dir = File.dirname dir
      `sudo chown idocus:idocus #{prev_dir}`
      FileUtils.mkdir_p dir
      FileUtils.cp old_path, new_path
    end
    'files'
  end

  before_content_post_process do |image|
    if image.dirty # halts processing
      false
    else
      true
    end
  end


  before_create :init_tags


  after_create do |document|
    unless document.mixed? || Rails.env.test?
      Document.delay_for(10.seconds, queue: :low).generate_thumbs(document.id)
      Document.delay_for(10.seconds, queue: :low).extract_content(document.id)
    end
  end


  scope :clean,            -> { where(dirty: false) }
  scope :mixed,            -> { where(origin: 'mixed') }
  scope :covers,           -> { where(is_a_cover: true) }
  scope :scanned,          -> { where(origin: 'scan') }
  scope :retrieved,        -> { where(origin: 'retriever') }
  scope :uploaded,         -> { where(origin: 'upload') }
  scope :not_mixed,        -> { where.not(origin: ['mixed']) }
  scope :extracted,        -> { where.not(content_text: ['']) }
  scope :not_clean,        -> { where(dirty: true) }
  scope :not_covers,       -> { where(is_a_cover: [false, nil]) }
  scope :not_extracted,    -> { where(content_text: '') }
  scope :cannot_extract,   -> { where(content_text: '-[none]') }
  scope :dematbox_scanned, -> { where(origin: 'dematbox_scan') }
  scope :by_position,      -> { order(position: :asc) }

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
    where('created_at >= ? AND created_at <= ?', start_at, end_at)
  }


  def as_indexed_json(_options = {})
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


  def self.search(text, options = {})
    page = options[:page] || 1
    per_page = options[:per_page] || default_per_page

    query = self.joins(:pack)

    query = query.where(id: options[:id]) if options[:id].present?
    query = query.where(id: options[:ids]) if options[:ids].present?
    query = query.where('packs.id = ?', options[:pack_id] )  if options[:pack_id].present?
    query = query.where('packs.id IN (?)', options[:pack_ids]) if options[:pack_ids].present?
    query = query.where('documents.tags LIKE ? OR documents.content_text LIKE ?', "%#{text}%", "%#{text}%") if text.present?

    query.order(position: :asc) if  options[:sort] == true

    query.page(page).per(per_page)
  end


  def self.generate_thumbs(id)
    document = Document.find(id)
    document.dirty = false

    document.content.reprocess!

    document.save
  end


  def self.extract_content(id)
    document = Document.find(id)
    path = if document.content.queued_for_write[:original]
             document.content.queued_for_write[:original].path
           else
             document.content.path
           end

    POSIX::Spawn.system "pdftotext -raw -nopgbrk -q #{path}"

    dirname  = File.dirname(path)
    filename = File.basename(path, '.pdf') + '.txt'
    filepath = File.join(dirname, filename)

    if File.exist?(filepath)
      text = File.open(filepath, 'r').readlines.map(&:strip).join(' ')
      # remove special character, which will not be used on search anyway
      text = text.each_char.select { |c| c.bytes.size < 4 }.join
      document.content_text = text
    end

    document.content_text = ' ' unless document.content_text.present?

    document.save
  end


  def get_token
    if token.present?
      token
    else
      update_attribute(:token, rand(36**50).to_s(36))
      token
    end
  end


  def get_access_url(style = :original)
    content.url(style) + '&token=' + get_token
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

    tags << number if !mixed? && number
  end


  def number
    content_file_name.split('_')[-1].to_i.to_s
  rescue
    nil
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


  def retrieved?
    origin == 'retriever'
  end
end
