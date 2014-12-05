# -*- encoding : UTF-8 -*-
class TempDocument
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Paperclip

  field :original_file_name

  field :content_file_name
  field :content_content_type
  field :content_file_size,    type: Integer
  field :content_updated_at,   type: Time

  field :raw_content_file_name
  field :raw_content_content_type
  field :raw_content_file_size,    type: Integer
  field :raw_content_updated_at,   type: Time
  field :pages_number,             type: Integer

  field :position,             type: Integer
  field :is_an_original,       type: Boolean, default: true # original or bundled
  field :is_a_cover,           type: Boolean, default: false
  field :is_ocr_layer_applied, type: Boolean

  field :delivered_by
  field :delivery_type

  field :dematbox_doc_id
  field :dematbox_box_id
  field :dematbox_service_id
  field :dematbox_text
  field :dematbox_is_notified
  field :dematbox_notified_at

  field :fiduceo_id
  field :fiduceo_metadata, type: Hash
  field :fiduceo_service_name
  field :fiduceo_custom_service_name

  field :signature

  field :is_corruption_notified, type: Boolean
  field :corruption_notified_at, type: Time

  field :state,                    default: 'created'
  field :stated_at, type: Time
  field :is_locked, type: Boolean, default: false

  validates_inclusion_of :delivery_type, within: %w(scan upload dematbox_scan fiduceo)

  index :delivery_type
  index :state
  index :is_an_original

  belongs_to :organization
  belongs_to :user
  belongs_to :temp_pack
  belongs_to :document_delivery
  belongs_to :fiduceo_retriever
  belongs_to :email
  belongs_to :piece, class_name: 'Pack::Piece', inverse_of: :temp_document
  has_mongoid_attached_file :content,     path: ":rails_root/files/:rails_env/:class/:id/:filename"
  has_mongoid_attached_file :raw_content, path: ":rails_root/files/:rails_env/:class/:id/raw_content/:filename"

  scope :locked,            where: { is_locked: true }
  scope :not_locked,        where: { is_locked: false }

  scope :scan,              where: { delivery_type: 'scan' }
  scope :upload,            where: { delivery_type: 'upload' }
  scope :dematbox_scan,     where: { delivery_type: 'dematbox_scan' }
  scope :fiduceo,           where: { delivery_type: 'fiduceo' }

  scope :originals,         where: { is_an_original: true }
  scope :bundled,           where: { is_an_original: false }

  scope :ocr_layer_applied, where: { is_ocr_layer_applied: true }

  scope :created,           where:  { state: 'created' }
  scope :unreadable,        where:  { state: 'unreadable' }
  scope :wait_selection,    where:  { state: 'wait_selection' }
  scope :ocr_needed,        where:  { state: 'ocr_needed' }
  scope :bundle_needed,     where:  { state: 'bundle_needed', is_locked: false }
  scope :bundling,          where:  { state: 'bundling' }
  scope :bundled,           where:  { state: 'bundled' }
  scope :ready,             where:  { state: 'ready', is_locked: false }
  scope :processed,         any_in: { state: %w(processed bundled) }
  scope :not_processed,     not_in: { state: %w(processed) }
  scope :valid,             any_in: { state: %w(ready ocr_needed bundle_needed bundling bundled processed) }

  state_machine :initial => :created do
    state :created
    state :unreadable
    state :wait_selection
    state :ocr_needed
    state :bundle_needed
    state :bundling
    state :bundled
    state :ready
    state :processed

    before_transition any => any do |temp_document, transition|
      temp_document.stated_at = Time.now
    end

    after_transition on: :ready do |temp_document, transition|
      temp_document.temp_pack.safely.inc(:document_not_processed_count, 1)
    end

    after_transition on: :processed do |temp_document, transition|
      temp_document.temp_pack.safely.inc(:document_not_processed_count, -1)
    end

    after_transition on: :bundle_needed do |temp_document, transition|
      temp_document.temp_pack.safely.inc(:document_bundle_needed_count, 1)
    end

    after_transition on: :bundling do |temp_document, transition|
      temp_document.temp_pack.safely.inc(:document_bundle_needed_count, -1)
      temp_document.temp_pack.safely.inc(:document_bundling_count, 1)
    end

    after_transition on: :bundled do |temp_document, transition|
      temp_document.temp_pack.safely.inc(:document_bundling_count, -1)
    end

    after_transition on: :ocr_needed do |temp_document, transition|
      TempDocument.send_to_ocr_processor(temp_document.id)
    end

    event :unreadable do
      transition :created => :unreadable
    end

    event :wait_selection do
      transition :created => :wait_selection
    end

    event :ocr_needed do
      transition :created => :ocr_needed
    end

    event :bundle_needed do
      transition [:created, :unreadable, :ocr_needed] => :bundle_needed
    end

    event :bundling do
      transition :bundle_needed => :bundling
    end

    event :bundled do
      transition :bundling => :bundled
    end

    event :ready do
      transition [:created, :unreadable, :wait_selection, :ocr_needed] => :ready
    end

    event :processed do
      transition [:ready] => :processed
    end
  end

  class << self
    def by_position
      asc(:position)
    end

    def find_with(options)
      where(options).first
    end

    def find_or_initialize_with(options)
      if (temp_document=find_with(options))
        temp_document
      else
        TempDocument.new(options)
      end
    end

    def find_by_dematbox_doc_id(id)
      where(dematbox_doc_id: id).first
    end

    def find_or_initialize_by_dematbox_doc_id(id)
      if (temp_document=find_by_dematbox_doc_id(id))
        temp_document
      else
        TempDocument.new(dematbox_doc_id: id)
      end
    end

    def send_to_ocr_processor(id)
      temp_document = TempDocument.find id
      doc_id = DematboxServiceApi.send_file(temp_document.content.path)
      temp_document.update_attribute(:dematbox_doc_id, doc_id)
    end
    handle_asynchronously :send_to_ocr_processor, priority: 0
  end

  def name_with_position
    name = File.basename self.content_file_name, '.*'
    name.sub!(/_\d+$/, '') if scanned?
    "#{name}_%0#{DocumentProcessor::POSITION_SIZE}d" % position
  end

  def file_name_with_position
    extension = File.extname(self.content_file_name)
    "#{name_with_position}#{extension}"
  end

  def scanned?
    delivery_type == 'scan'
  end

  def uploaded?
    delivery_type == 'upload'
  end

  def scanned_by_dematbox?
    delivery_type == 'dematbox_scan'
  end

  def fiduceo?
    delivery_type == 'fiduceo'
  end

  def is_a_cover?
    if scanned?
      if original_file_name.present?
        File.basename(original_file_name, '.*').gsub(' ', '_').split('_')[3].match(/^0*$/).present?
      else
        is_a_cover
      end
    else
      false
    end
  end

  def burst(dir='/tmp')
    Pdftk.new.burst content.path, dir, name_with_position, DocumentProcessor::POSITION_SIZE
  end

  def corruption_notified
    self.is_corruption_notified = true
    self.corruption_notified_at = Time.now
    save
  end
end
