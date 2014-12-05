# -*- encoding : UTF-8 -*-
class TempPack
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name # ex : TS0001 TS 201301 all
  field :position_counter,             type: Integer, default: 0
  field :document_not_processed_count, type: Integer, default: 0
  field :document_bundling_count,      type: Integer, default: 0
  field :document_bundle_needed_count, type: Integer, default: 0

  validates_presence_of :name
  validates_uniqueness_of :name

  index :name, unique: true
  index :document_not_processed_count
  index :document_bundling_count
  index :document_bundle_needed_count

  belongs_to :organization
  belongs_to :user
  belongs_to :document_delivery
  has_many :temp_documents, dependent: :destroy

  scope :not_processed, where: { :document_not_processed_count.gt => 0 }
  scope :bundling,      where: { :document_bundling_count.gt => 0 }
  scope :bundle_needed, where: { :document_bundle_needed_count.gt => 0 }
  scope :not_recently_updated, lambda { where(:updated_at.lt => 5.minutes.ago) }

  class << self
    def find_by_name(name)
      where(name: name).first
    end

    def find_or_create_by_name(name)
      if (temp_pack=find_by_name(name))
        temp_pack
      else
        temp_pack = TempPack.new
        temp_pack.name = name
        temp_pack.user = User.find_by_code name.split[0]
        temp_pack.organization = temp_pack.user.try(:organization)
        temp_pack.save
        temp_pack
      end
    end
  end

  def journal
    user.account_book_types.where(name: name.split[1]).first if user
  end

  def period
    name.split[2]
  end

  def is_bundle_needed
    journal.try(:compta_processable?) || false
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
    elsif options[:signature].present?
      opts = { signature: options[:signature], user_id: options[:user_id] }
      temp_document = TempDocument.find_or_initialize_with opts
    else
      temp_document ||= TempDocument.new
    end

    if options[:delivery_type] != 'fiduceo' || !temp_document.persisted?
      temp_document.temp_pack           = self
      temp_document.user                = user
      temp_document.organization        = organization
      temp_document.original_file_name  = options[:original_file_name]
      temp_document.content             = file
      temp_document.position            = next_document_position unless temp_document.position

      temp_document.delivered_by        = options[:delivered_by]
      temp_document.delivery_type       = options[:delivery_type]

      temp_document.dematbox_box_id     = options[:dematbox_box_id]     if options[:dematbox_box_id]
      temp_document.dematbox_service_id = options[:dematbox_service_id] if options[:dematbox_service_id]
      temp_document.dematbox_text       = options[:dematbox_text]       if options[:dematbox_text]

      temp_document.fiduceo_id                  = options[:fiduceo_id]          if options[:fiduceo_id]
      temp_document.fiduceo_metadata            = options[:fiduceo_metadata]    if options[:fiduceo_metadata]
      temp_document.fiduceo_service_name        = options[:service_name]        if options[:service_name]
      temp_document.fiduceo_custom_service_name = options[:custom_service_name] if options[:custom_service_name]

      temp_document.save
      if options[:is_content_file_valid]
        temp_document.pages_number = DocumentTools.pages_number(temp_document.content.path)
        temp_document.save
        if temp_document.fiduceo?
          options[:wait_selection] ? temp_document.wait_selection : temp_document.ready
        else
          if DematboxServiceApi.config.is_active && temp_document.uploaded? && DocumentTools.need_ocr?(temp_document.content.path)
            temp_document.ocr_needed
          else
            is_bundle_needed ? temp_document.bundle_needed : temp_document.ready
          end
        end
      else
        temp_document.unreadable
      end
      set_updated_at
      save
    end
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

  def ready_fiduceo_documents
    temp_documents.fiduceo.by_position.ready
  end

  def ready_documents
    documents = ready_uploaded_documents
    documents += ready_dematbox_documents
    documents += ready_fiduceo_documents
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
