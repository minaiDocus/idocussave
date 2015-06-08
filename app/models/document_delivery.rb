# -*- encoding : UTF-8 -*-
class DocumentDelivery
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Paperclip

  field :provider
  field :date,         type: Date
  field :is_processed, type: Boolean
  field :processed_at, type: Time
  field :position,     type: Integer, default: 1

  has_many :temp_packs
  has_many :temp_documents

  scope :for_provider, -> provider { where(provider: provider) }
  scope :processed,    -> { where(is_processed: true) }

  def processed
    self.is_processed = true
    self.processed_at = Time.now
    save
  end

  def valid_documents?
    temp_documents.valid.count == temp_documents.count
  end

  def file_names
    @file_names ||= temp_documents.valid.distinct(:content_file_name)
  end

  def include?(file_name)
    file_names.include? file_name
  end

  def add_or_replace(file, options={})
    pack_name = DocumentTools.pack_name options[:original_file_name]
    temp_pack = TempPack.find_or_create_by_name pack_name
    temp_pack.update_pack_state

    temp_document = temp_documents.where(original_file_name: options[:original_file_name]).first

    is_valid = DocumentTools.completed?(file.path)
    if temp_document
      replace temp_document, file if is_valid
    else
      opts = options.dup
      opts[:is_content_file_valid] = is_valid
      opts[:is_locked] = true
      temp_document = temp_pack.add file, opts
      temp_documents << temp_document
    end
    temp_document
  end

  def replace(temp_document, file)
    temp_document.content = file
    temp_document.save
    temp_document.temp_pack.is_bundle_needed? ? temp_document.bundle_needed : temp_document.ready
  end

  class << self
    def by_date
      asc(:date)
    end

    def by_position
      asc(:position)
    end

    def find_by(date, provider, position=1)
      DocumentDelivery.where(date: date, provider: provider, position: position).first
    end

    def find_or_create_by(date, provider, position=1)
      if (document_delivery=find_by(date, provider, position))
        document_delivery
      else
        DocumentDelivery.create(date: date, provider: provider, position: position)
      end
    end
  end
end
