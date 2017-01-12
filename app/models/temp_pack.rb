# -*- encoding : UTF-8 -*-
class TempPack < ActiveRecord::Base
  validates_presence_of :name
  validates_uniqueness_of :name

  has_many :temp_documents, dependent: :destroy

  belongs_to :user
  belongs_to :organization
  belongs_to :document_delivery



  scope :bundling,             -> { where("document_bundling_count > ?", 0) }
  scope :bundle_needed,        -> { where("document_bundle_needed_count > ?", 0) }
  scope :not_published,        -> { where('document_not_processed_count > ? OR document_bundling_count > ? OR document_bundle_needed_count > ?', 0, 0, 0) }
  scope :not_processed,        -> { where("document_not_processed_count > ?", 0) }
  scope :not_recently_updated, -> { where("updated_at < ?", 15.minutes.ago) }


  def self.find_by_name(name)
    where(name: name).first
  end


  def self.find_or_create_by_name(name)
    if (temp_pack = find_by_name(name))
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
