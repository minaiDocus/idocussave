# -*- encoding : UTF-8 -*-
class TempPack
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name # ex : TS0001 TS 201301 all
  field :position_counter,             type: Integer, default: 0
  field :document_not_processed_count, type: Integer, default: 0
  field :document_not_bundled_count,   type: Integer, default: 0
  field :is_bundle_needed,             type: Boolean, default: false

  validates_presence_of :name
  validates_uniqueness_of :name

  index :name, unique: true
  index :document_not_processed_count
  index :document_not_bundled_count

  belongs_to :document_delivery
  has_many :temp_documents, dependent: :destroy

  scope :not_processed, where: { :document_not_processed_count.gt => 0 }
  scope :not_bundled,   where: { :document_not_bundled_count.gt => 0 }
  scope :not_recently_updated, lambda { where(:updated_at.lt => 5.minutes.ago) }

  class << self
    def find_by_name(name)
      where(name: name).first
    end

    def find_or_create_by_name(name)
      if (temp_pack = find_by_name(name))
        temp_pack
      else
        is_bundle_needed = false
        user_code, journal_name = name.split[0..1]
        user = User.find_by_code user_code
        if user
          journal = user.account_book_types.where(name: journal_name).first
          is_bundle_needed = journal.compta_processable? if journal
        end
        TempPack.create(name: name, is_bundle_needed: is_bundle_needed)
      end
    end
  end

  def basename
    self.name.sub(' all', '')
  end

  def basefilename
    basename.gsub(' ', '_') + '.pdf'
  end

  def add(file, options={})
    if options[:dematbox_doc_id].present?
      opts = { dematbox_doc_id: options[:dematbox_doc_id] }
      temp_document = TempDocument.find_or_initialize_with opts
    else
      temp_document ||= TempDocument.new
    end

    temp_document.is_locked           = options[:is_locked] || false
    temp_document.temp_pack           = self
    temp_document.original_file_name  = options[:original_file_name]
    temp_document.content             = file
    temp_document.position            = next_document_position

    temp_document.delivered_by        = options[:delivered_by]
    temp_document.delivery_type       = options[:delivery_type]

    temp_document.dematbox_box_id     = options[:dematbox_box_id]     if options[:dematbox_box_id]
    temp_document.dematbox_service_id = options[:dematbox_service_id] if options[:dematbox_service_id]
    temp_document.dematbox_text       = options[:dematbox_text]       if options[:dematbox_text]

    temp_document.save
    if options[:is_content_file_valid]
      is_bundle_needed ? temp_document.bundle_needed : temp_document.ready
    else
      temp_document.unreadable
    end
    set_updated_at
    save
    temp_document
  end

  def ready_scanned_documents
    if temp_documents.scan.unreadable.count == 0
      temp_documents.scan.by_position.ready
    else
      []
    end
  end

  def ready_dematbox_documents
    temp_documents.dematbox_scan.by_position.ready
  end

  def ready_uploaded_documents
    temp_documents.upload.by_position.ready
  end

  def ready_documents
    documents = ready_uploaded_documents
    documents += ready_dematbox_documents
    documents += ready_scanned_documents
    documents
  end

  def next_document_position
    safely.inc(:position_counter, 1)
  end

private

  def new_file_name(file_name, position)
    number = "%03d" % position
    if file_name.match /_\d{3}.pdf$/
      file_name.sub(/_\d{3}.pdf$/,"_#{number}.pdf")
    else
      file_name.sub(/.pdf$/,"_#{number}.pdf")
    end
  end
end
