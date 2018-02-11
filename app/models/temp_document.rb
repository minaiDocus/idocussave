# -*- encoding : UTF-8 -*-
class TempDocument < ActiveRecord::Base
  serialize :scan_bundling_document_ids, Array

  validates_inclusion_of :delivery_type, within: %w(scan upload dematbox_scan retriever)

  serialize :retrieved_metadata, Hash
  serialize :metadata, Hash

  belongs_to :user
  belongs_to :email
  belongs_to :piece, class_name: 'Pack::Piece', inverse_of: :temp_document
  belongs_to :temp_pack
  belongs_to :organization
  belongs_to :document_delivery
  belongs_to :retriever
  belongs_to :ibizabox_folder
  belongs_to :analytic_reference
  has_many :notifiable_document_being_processed, dependent: :destroy
  has_many :notifiable_published_documents, dependent: :destroy
  # TODO : rename me
  has_one    :metadata2, class_name: 'TempDocumentMetadata'

  has_attached_file :content, styles: { medium: ['92x133', :png] },
                              path: ':rails_root/files/:rails_env/:class/:mongo_id_or_id/:filename',
                              url: '/account/documents/processing/:id/download/:style'
  do_not_validate_attachment_file_type :content

  has_attached_file :raw_content, path: ':rails_root/files/:rails_env/:class/:mongo_id_or_id/raw_content/:filename'
  do_not_validate_attachment_file_type :raw_content

  Paperclip.interpolates :mongo_id_or_id do |attachment, style|
    attachment.instance.mongo_id || attachment.instance.id
  end

  before_content_post_process :is_thumb_generated


  after_create do |temp_document|
    unless Rails.env.test?
      TempDocument.delay_for(10.seconds, queue: :low).generate_thumbs(temp_document.id)
    end
  end

  after_save do |temp_document|
    unless Rails.env.test?
      Rails.cache.write(['user', temp_document.user.id, 'temp_documents', 'last_updated_at'], Time.now.to_i)
    end
  end

  scope :scan,              -> { where(delivery_type: 'scan') }
  scope :valid,             -> { where(state: %w(ready ocr_needed bundle_needed bundling bundled processed)) }
  scope :ready,             -> { where(state: 'ready', is_locked: false) }
  scope :locked,            -> { where(is_locked: true) }
  scope :upload,            -> { where(delivery_type: 'upload') }
  scope :retrieved,         -> { where(delivery_type: 'retriever') }
  scope :created,           -> { where(state: 'created') }
  scope :bundled,           -> { where(state: 'bundled') }
  scope :bundling,          -> { where(state: 'bundling') }
  scope :originals,         -> { where(is_an_original: true) }
  scope :processed,         -> { where(state: %w(processed bundled)) }
  scope :not_locked,        -> { where(is_locked: false) }
  scope :unreadable,        -> { where(state: 'unreadable') }
  scope :ocr_needed,        -> { where(state: 'ocr_needed') }
  scope :by_position,       -> { order(position: :asc) }
  scope :not_processed,     -> { where.not(state: %w(processed)) }
  scope :dematbox_scan,     -> { where(delivery_type: 'dematbox_scan') }
  scope :not_published,     -> { where.not(state: %w(processed bundled wait_selection unreadable)) }
  scope :bundle_needed,     -> { where(state: 'bundle_needed', is_locked: false) }
  scope :wait_selection,    -> { where(state: 'wait_selection') }
  scope :ocr_layer_applied, -> { where(is_ocr_layer_applied: true) }
  scope :from_ibizabox,     -> { where.not(ibizabox_folder_id: nil) }


  state_machine initial: :created do
    state :ready
    state :created
    state :bundled
    state :bundling
    state :processed
    state :unreadable
    state :ocr_needed
    state :bundle_needed
    state :wait_selection


    before_transition any => any do |temp_document, _transition|
      temp_document.stated_at = Time.now
    end


    after_transition on: :ready do |temp_document, _transition|
      temp_document.temp_pack.increment_counter!(:document_not_processed_count, 1)
    end


    after_transition on: :processed do |temp_document, _transition|
      temp_document.temp_pack.increment_counter!(:document_not_processed_count, -1)
    end


    after_transition on: :bundle_needed do |temp_document, _transition|
      temp_document.temp_pack.increment_counter!(:document_bundle_needed_count, 1)
    end


    after_transition on: :bundling do |temp_document, _transition|
      temp_document.temp_pack.increment_counter!(:document_bundle_needed_count, -1)
      temp_document.temp_pack.increment_counter!(:document_bundling_count, 1)
    end


    after_transition on: :bundled do |temp_document, _transition|
      temp_document.temp_pack.increment_counter!(:document_bundling_count, -1)
    end


    after_transition on: :ocr_needed do |temp_document, _transition|
      AccountingWorkflow::OcrProcessing.send_document(temp_document.id)
    end


    event :unreadable do
      transition created: :unreadable
    end


    event :wait_selection do
      transition created: :wait_selection
    end


    event :ocr_needed do
      transition [:created, :wait_selection] => :ocr_needed
    end


    event :bundle_needed do
      transition [:created, :unreadable, :wait_selection, :ocr_needed] => :bundle_needed
    end


    event :bundling do
      transition bundle_needed: :bundling
    end


    event :bundled do
      transition bundling: :bundled
    end


    event :ready do
      transition [:created, :unreadable, :wait_selection, :ocr_needed] => :ready
    end


    event :processed do
      transition [:ready] => :processed
    end
  end


  def self.find_with(options)
    where(options).first
  end


  def self.find_or_initialize_with(options)
    if (temp_document = find_with(options))
      temp_document
    else
      TempDocument.new(options)
    end
  end


  def self.find_by_dematbox_doc_id(id)
    where(dematbox_doc_id: id).first
  end


  def self.find_or_initialize_by_dematbox_doc_id(id)
    if (temp_document = find_by_dematbox_doc_id(id))
      temp_document
    else
      TempDocument.new(dematbox_doc_id: id)
    end
  end


  def self.generate_thumbs(id)
    temp_document = TempDocument.find(id)

    temp_document.is_thumb_generated = true # set to true before reprocess to pass `before_content_post_process`
    temp_document.content.reprocess!

    temp_document.save
  end


  def self.search_dematbox_files(contains)
    dematbox_files = TempDocument.dematbox_scan.originals

    dematbox_files = dematbox_files.where(dematbox_doc_id: contains[:dematbox_doc_id]) if contains[:dematbox_doc_id]

    if contains[:created_at]
      contains[:created_at].each do |operator, value|
        dematbox_files = dematbox_files.where("created_at #{operator} ?", value) if operator.in?(['>=', '<='])
      end
    end

    dematbox_files.where(delivered_by: contains[:delivered_by]) if contains[:delivered_by]

    dematbox_files = dematbox_files.where('content_file_name LIKE ?', "%#{contains[:content_file_name]}%") if contains[:content_file_name]

    dematbox_files = dematbox_files.where(dematbox_is_notified: contains[:dematbox_is_notified]) if contains[:dematbox_is_notified]

    dematbox_files
  end


  def self.search_for_collection(collection, contains)
    user = collection.first.user if collection.first

    if user
      if contains[:service_name]
        retriever_ids = user.retrievers.where("name LIKE ?", "%#{contains[:service_name]}%").pluck(:id)
        collection = collection.where(retriever_id: retriever_ids)
      elsif contains[:retriever_id]
        retriever = user.retrievers.find(contains[:retriever_id])
        collection = collection.where(retriever_id: retriever.id)
      end

      if contains[:transaction_id]
        transaction = user.fiduceo_transactions.find(contains[:transaction_id])
        documents = collection.where(fiduceo_id: transaction.retrieved_document_ids)
      end
    end

    if contains[:date]
      contains[:date].each do |operator, value|
        collection = collection.where("temp_document_metadata.date #{operator} ?", value) if operator.in?(['>=', '<='])
      end
    end
    collection = collection.where("temp_document_metadata.name LIKE ?", "%#{contains[:name]}%") if contains[:name].present?
    collection = collection.where("temp_document_metadata.amount = ?", contains[:amount].to_f) if contains[:amount].present?

    collection
  end

  def self.search_ibizabox_collection(collection, contains)
    if contains[:name]
      collection = collection.where("original_file_name LIKE ?", "%#{contains[:name]}%")
    end

    if contains[:journal]
      collection = collection.where("account_book_types.name LIKE ?", "%#{contains[:journal]}%")
    end

    if contains[:date]
      contains[:date].each do |operator, value|
        collection = collection.where("created_at #{operator} ?", value) if operator.in?(['>=', '<='])
      end
    end

    collection
  end


  def name_with_position
    name = File.basename content_file_name, '.*'
    name.sub!(/_\d+\z/, '') if scanned?

    "#{name}_%0#{AccountingWorkflow::TempPackProcessor::POSITION_SIZE}d" % position
  end


  def file_name_with_position
    extension = File.extname(content_file_name)

    "#{name_with_position}#{extension}"
  end


  def scanned?
    delivery_type == 'scan'
  end


  def uploaded?
    delivery_type == 'upload'
  end


  def scanned_with_dematbox?
    delivery_type == 'dematbox_scan'
  end


  def retrieved?
    delivery_type == 'retriever'
  end

  def from_ibizabox?
    delivered_by == 'ibiza'
  end


  def is_a_cover?
    if scanned?
      if original_file_name.present?
        case original_file_name
        when /\A#{Pack::CODE_PATTERN}(_| )#{Pack::JOURNAL_PATTERN}(_| )#{Pack::PERIOD_PATTERN}(_| )#{Pack::POSITION_PATTERN}#{Pack::EXTENSION_PATTERN}\z/
          File.basename(original_file_name, '.*').tr(' ', '_').split('_')[3].match(/\A0*\z/).present?
        when /\A#{Pack::CODE_PATTERN}(_| )#{Pack::JOURNAL_PATTERN}(_| )#{Pack::PERIOD_PATTERN}(_| )page\d{3,4}#{Pack::EXTENSION_PATTERN}\z/
          File.basename(original_file_name, '.*').tr(' ', '_').split('_')[3].match(/\Apage0001\z/).present?
        end
      else
        is_a_cover
      end
    else
      false
    end
  end


  def corruption_notified
    self.is_corruption_notified = true
    self.corruption_notified_at = Time.now

    save
  end
end
