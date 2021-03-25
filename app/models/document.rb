# -*- encoding : UTF-8 -*-
class Document < ApplicationRecord
  ATTACHMENTS_URLS={'cloud_content' => '/account/documents/:id/download/:style'}

  serialize :tags


  validates :origin, inclusion: { within: %w(mixed scan upload dematbox_scan retriever) }


  has_many :remote_files, as: :remotable, dependent: :destroy

  belongs_to :pack, optional: true

  has_one_attached :cloud_content
  has_one_attached :cloud_content_thumbnail

  has_attached_file :content,
                            styles: {
                              thumb: ['46x67>', :png],
                              medium: ['92x133', :png]
                            },
                            path: ':rails_root/files/:rails_env/:class/:attachment/:mongo_id_or_id/:style/:filename',
                            url: '/account/documents/:id/download/:style'
  do_not_validate_attachment_file_type :content

  Paperclip.interpolates :mongo_id_or_id do |attachment, style|
    attachment.instance.mongo_id || attachment.instance.id
  end

  before_content_post_process do |image|
    if image.dirty # halts processing
      false
    else
      true
    end
  end


  before_create :init_tags

  before_destroy do |document|
    document.cloud_content.purge
  end

  after_create_commit do |document|
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

    base_file_name = document.cloud_content.filename.to_s.gsub('.pdf', '')

    image = MiniMagick::Image.read(document.cloud_content.download).format('png').resize('92x133')
    

    document.cloud_content_thumbnail.attach(io: File.open(image.tempfile), 
                                                 filename: "#{base_file_name}.png", 
                                                 content_type: "image/png")

    document.save
  end


  def self.extract_content(id)
    document = Document.find(id)
    path = document.cloud_content_object.path

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

  def cloud_content_object
    CustomActiveStorageObject.new(self, :cloud_content)
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
    "/account/documents/documents/#{id}/download/#{style}" + '?token=' + get_token
  end


  def append(file_path)
    CustomUtils.mktmpdir('document_1') do |dir|
      merged_file_path = File.join(dir, content_file_name)

      Pdftk.new.merge([self.cloud_content_object.path, file_path], merged_file_path)

      if DocumentTools.modifiable?(merged_file_path)
        self.cloud_content_object.attach(File.open(merged_file_path), content_file_name) if save
      end
    end
  end


  def prepend(file_path)
    CustomUtils.mktmpdir('document_2') do |dir|
      merged_file_path = File.join(dir, content_file_name)

      Pdftk.new.merge([file_path, self.cloud_content_object.path], merged_file_path)

      if DocumentTools.modifiable?(merged_file_path)
        self.cloud_content_object.attach(File.open(merged_file_path), content_file_name) if save
      end
    end
  end


  def init_tags
    self.tags = pack.name.downcase.sub(' all', '').split

    tags << number if !mixed? && number
  end

  def get_tags(separator='-')
    filters = self.pack.name.split.collect do |f|
      f.strip.match(/^[0-9]+$/) ? f.strip.to_i.to_s : f.strip.downcase
    end

    _tags = self.tags.present? ? self.tags.select{ |tag| !filters.include?(tag.to_s.strip.downcase) } : []

    _tags.join(" #{separator} ").presence || '-'
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
