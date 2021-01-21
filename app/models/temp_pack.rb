# -*- encoding : UTF-8 -*-
class TempPack < ApplicationRecord
  validates_presence_of :name
  validates_uniqueness_of :name

  has_many :temp_documents, dependent: :destroy

  belongs_to :user
  belongs_to :organization
  belongs_to :document_delivery, optional: true


  scope :not_recently_updated, -> { where("updated_at < ?", 15.minutes.ago) }


  def self.find_by_name(name)
    where(name: name).first
  end


  def self.find_or_create_by_name(name)
    self.find_or_initialize_by(name: name) do |temp_pack|
      temp_pack.name = name
      temp_pack.user = User.find_by_code name.split[0]
      temp_pack.organization = temp_pack.user.try(:organization)

      temp_pack.save

      temp_pack
    end
  end

  def self.bundle_processable
    bundle_needed.not_recently_updated.order(updated_at: :asc).select { |temp_pack| temp_pack.temp_documents.ocr_needed.size == 0 }
  end


  def self.temp_documents
    joins(:temp_documents)
  end


  def self.bundle_needed
    temp_documents.where('temp_documents.state = ?', 'undle_needed')
  end


  def self.not_published
    temp_documents.where('temp_documents.state IN (?)', ['bundle_needed', 'ready'])
  end


  def self.not_processe
    temp_documents.where('temp_documents.state = ?', 'ready')
  end


  def update_pack_state
    if journal && journal.compta_processable?
      pack = Pack.find_or_initialize(name, user)
      pack.update_attribute(:is_fully_processed, false) if pack.is_fully_processed
    end
  end


  def journal
    user.account_book_types.where(name: name.split[1]).first if user
  end


  def period
    name.split[2]
  end


  def is_bundle_needed?
    journal.try(:compta_processable?) || false
  end


  def is_pre_assignment_needed?
    journal.try(:compta_processable?) || false
  end


  def basename
    name.sub(' all', '')
  end


  def basefilename
    basename.tr(' ', '_') + '.pdf'
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


  def ready_retrieved_documents
    temp_documents.retrieved.by_position.ready
  end


  def ready_documents
    documents = ready_uploaded_documents
    documents += ready_dematbox_documents
    documents += ready_retrieved_documents
    documents += ready_scanned_documents
    documents
  end


  def next_document_position
    self.with_lock do
      increment!(:position_counter, 1)
      position_counter
    end
  end

  def increment_counter!(counter, value)
    self.with_lock do
      increment!(counter, value)
    end
  end

  def not_processed?
    temp_documents.where(state: 'ready').size > 0
  end

  def not_processed_count
    temp_documents.where(state: 'ready').size
  end

  def bundle_needed_count
    temp_documents.where(state: 'bundle_needed').size
  end

  private


  def new_file_name(file_name, position)
    number = '%03d' % position
    if file_name =~ /_\d{3}.pdf\z/
      file_name.sub(/_\d{3}.pdf\z/, "_#{number}.pdf")
    else
      file_name.sub(/.pdf\z/, "_#{number}.pdf")
    end
  end
end
